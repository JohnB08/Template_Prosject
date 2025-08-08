variable "hcloud_token"{
    description = "Hetzner Api Token"
    type = string
    sensitive = true
}

variable "user" {
  type = string
  default = "ubuntu"
  description = "OS User"
}