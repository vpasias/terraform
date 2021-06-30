# variables that can be overriden
variable "hostname" { default = "node" }
variable "domain" { default = "example.com" }
variable "ip_type" { default = "static" } # dhcp is other valid type
variable "memoryMB" { default = 1024*1 }
variable "cpu" { default = 1 }
variable "prefixIP" { default = "192.168.122" }
variable "octetIP" { default = "31" }
variable "nodes" { default = "4" }

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

# fetch the latest ubuntu release image from their mirrors
resource "libvirt_volume" "os_image" {
  name = "os_image"
  pool = "default"
  # using newest ubuntu focal 20.04
  #source = "https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img"
  source = "https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img"
  format = "qcow2"
}

# Use CloudInit ISO to add ssh-key to the instance
resource "libvirt_cloudinit_disk" "commoninit" {
          name = "${var.hostname}-commoninit.iso"
          pool = "default"
          user_data = data.template_file.user_data.rendered
          network_config = data.template_file.network_config.rendered
}


resource "libvirt_volume" "volume" {
  name           = "volume-${count.index}"
  base_volume_id = libvirt_volume.os_image.id
  count          = 4
  pool = "default"
}

resource "libvirt_domain" "node" {
  name = "node-${count.index}"
  memory = "8192"
  vcpu   = 2
  disk {
    volume_id = element(libvirt_volume.volume.*.id, count.index)
  }
 
  cloudinit = libvirt_cloudinit_disk.commoninit.id

  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  count = 4
}

output "ips" {
  value = libvirt_domain.node.*.network_interface.0.addresses
}
