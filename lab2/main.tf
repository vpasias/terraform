terraform {
  required_version = ">= 0.13"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.6.2"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

variable "hostname" { default = "node" }
variable "memoryMB" { default = 1024 * 8 }
variable "cpu" { default = 2 }
variable "serverCount" { default = 3 }
variable "network" { default = "mnet" }

resource "libvirt_volume" "os_image" {
  name   = "os_image"
  source = "http://cloud.centos.org/centos/8-stream/x86_64/images/CentOS-Stream-GenericCloud-8-20210603.0.x86_64.qcow2"
}

resource "libvirt_volume" "volume" {
  count          = var.serverCount
  name           = "volume-${count.index}"
  base_volume_id = libvirt_volume.os_image.id
  format         = "qcow2"
}

resource "libvirt_cloudinit_disk" "commoninit" {
  count     = var.serverCount
  name      = "${var.hostname}-commoninit-${count.index}.iso"
  user_data = data.template_file.user_data[count.index].rendered
}


data "template_file" "user_data" {
  count    = var.serverCount
  template = file("${path.module}/cloud_init.cfg")
  vars = {
    hostname = "${var.hostname}-${count.index}"
  }
}

resource "libvirt_network" "network" {
  name      = var.network
  domain    = "libvirt.local"
  addresses = ["192.168.125.0/24"]
  dhcp {
    enabled = true
  }
  dns {
    enabled = true
  }
}

resource "libvirt_domain" "domain" {
  count      = var.serverCount
  name       = "node-${count.index}"
  memory     = var.memoryMB
  vcpu       = var.cpu
  qemu_agent = true
  autostart  = true
  cpu = { mode = "host-passthrough" }

  disk {
    volume_id = element(libvirt_volume.volume.*.id, count.index)
  }

  network_interface {
    network_id     = libvirt_network.network.id
    network_name   = var.network
    addresses      = ["192.168.125.${count.index + 10}"]
    mac            = "52:54:00:b2:2f:${count.index + 10}"
    wait_for_lease = true
  }
  
  console {
    target_type = "serial"
    type        = "pty"
    target_port = "0"
  }
  
  console {
    target_type = "virtio"
    type        = "pty"
    target_port = "1"
  }

  depends_on = [
    libvirt_network.network,
  ]

  cloudinit = libvirt_cloudinit_disk.commoninit[count.index].id
}

output "ips" {
  value = libvirt_domain.domain.*.network_interface.0.addresses
}
