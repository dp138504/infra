terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.20.1"
    }
  }
}

provider "proxmox" {
  endpoint = var.pve_endpoint
  username = var.pve_username
  password = var.pve_passowrd
  insecure = true
}