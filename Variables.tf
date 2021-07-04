variable "domain" {
  description = "The domain/host name of the zone"
  default     = "terraforming_2004"
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
  description = "The mac & iP address for this VM"
  # 80G
  default = 80 * 1024 * 1024 * 1024
}
