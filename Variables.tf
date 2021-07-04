variable "domain" {
  description = "The domain/host name of the zone"
  default     = "Node1"
}

variable "ssh_port" {
  description = "The sshd port of the VM"
  default     = 22
}

variable "IP_addr" {
  description = "The mac & iP address for this VM"
  default     = 33
}

variable "vol_size" {
  description = "The disk size for this VM"
  # 80G
  default = 80 * 1024 * 1024 * 1024
}
