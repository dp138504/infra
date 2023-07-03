data "proxmox_virtual_environment_datastores" "odin_ds" {
  node_name = "odin-pve"
}

data "proxmox_virtual_environment_datastores" "thor_ds" {
  node_name = "thor-pve"
}

data "proxmox_virtual_environment_datastores" "loki_ds" {
  node_name = "loki-pve"
}

data "proxmox_virtual_environment_datastores" "hela_ds" {
  node_name = "hela-pve"
}

data "proxmox_virtual_environment_vm" "ubuntu-2204-cloudimg-amd64" {
  node_name = "loki-pve"
  vm_id     = 1000
}