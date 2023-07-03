variable "pve_username" {
  default = "root@pam"
  type = string
  description = "Username of the PVE account"
}

variable "pve_passowrd" {
  sensitive = true
  type = string
  description = "Password of the PVE account"
}

variable "pve_endpoint" {
  type = string
  description = "URL of the PVE endpoint"
  default = "https://172.16.5.1:8006/"
}