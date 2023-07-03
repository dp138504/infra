packer {
  required_plugins {
    proxmox-iso = {
      version = " >= 1.1.3"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

variable "proxmox_api_url" {
  type        = string
  default     = "https://odin-pve.crossfits.dpitts.us/api2/json"
  description = "URL of the PVE API endpoint"
}

variable "proxmox_api_token_id" {
  type    = string
  default = "root@pam!pakcer"
  description = "ID of the API token used for provisioning"
}

variable "proxmox_api_token_secret" {
  type        = string
  sensitive   = true
  description = "API secret for the token used for provisioning"
}

variable "ssh_packer_password" {
  type      = string
  sensitive = true
  description = "SSH password that packer will use for provisioning"
}

variable "node_name" {
  type      = string
  default   = "thor-pve"
  description = "PVE node name for use in the manifest file. For further use with Terraform."
}

source "proxmox-iso" "ubuntu-2204-amd64-qemu" {
  proxmox_url              = "${var.proxmox_api_url}"
  username                 = "${var.proxmox_api_token_id}"
  token                    = "${var.proxmox_api_token_secret}"
  insecure_skip_tls_verify = true

  # OS Source; iso_file and iso_url are mutually exclusive
  unmount_iso      = true # Unmount ISO when complete
  iso_storage_pool = "crossfits-cephfs"
  iso_file         = "crossfits-cephfs:iso/ubuntu-22.04.2-live-server-amd64.iso"
  #iso_url         = "https://releases.ubuntu.com/22.04.2/ubuntu-22.04.2-live-server-amd64.iso"
  #iso_checksum    = "5e38b55d57d94ff029719342357325ed3bda38fa80054f9330dc789cd2d43931"

  # VM Settings
  qemu_agent              = true
  template_description    = "Ubuntu Jammy (LTS 22.04.2) - Base"
  node                    = "${var.node_name}"
  vm_id                   = "9000"
  vm_name                 = "ubuntu-2204-amd64-qemu"
  cpu_type                = "host"
  cores                   = "2"
  os                      = "l26" # Linux 2.6+
  memory                  = "4096"
  bios                    = "ovmf"
  machine                 = "q35"
  serials                 = ["socket"]
  cloud_init              = false
  #cloud_init_storage_pool = "crossfits-ec"

  vga {
    type = "std"
  }

  scsi_controller = "virtio-scsi-single"
  disks {
    disk_size    = "10G"
    format       = "raw"
    storage_pool = "crossfits-ec"
    type         = "virtio"
    io_thread    = "true"
    cache_mode   = "writeback"
  }
  efi_config {
    efi_storage_pool = "crossfits-ec"
  }

  network_adapters {
    model         = "virtio"
    bridge        = "vmbr0"
    firewall      = "false"
    packet_queues = "4"
  }

  # Packer Boot Commands
  boot_wait = "15s"
  boot_command = [
    "e<down><down><down>",
    "<end>",
    "<bs><bs><bs><bs>",
    "autoinstall ds='nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/' ",
    "--- <F10>"
  ]

  # Packer Auto-install Settings
  http_directory    = "http"
  http_bind_address = "192.168.86.246"
  http_port_min     = 8802
  http_port_max     = 8802

  ssh_username = "packer"

  # Packer connection settings; ssh_password and ssh_private_key_file are mutually exclusivs
  ssh_password = "${var.ssh_packer_password}"
  #ssh_private_key_file = "/home/dap/.ssh/id_ed25519.vms"

  # Raise the timeout, when installation takes longer
  ssh_timeout = "30m"
}

build {
  name    = "ubuntu-2204-amd64-qemu"
  sources = ["proxmox-iso.ubuntu-2204-amd64-qemu"]

  # System generalization and cloud-init reset from subiquity.
  provisioner "shell" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
      "sudo rm /etc/ssh/ssh_host_*",
      "sudo truncate -s 0 /etc/machine-id",
      "sudo apt -y autoremove --purge",
      "sudo apt -y clean",
      "sudo apt -y autoclean",
      "sudo cloud-init clean",
      "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
      "sudo sync"
    ]
  }

  # Copy cloud-init datasource configuration to template
  provisioner "file" {
    source      = "files/99-pve.cfg"
    destination = "/tmp/99-pve.cfg"
  }

  # Move 99-pve.cfg to correct location and remove default datasource configuration
  provisioner "shell" {
    inline = [
      "sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg",
      "sudo rm /etc/cloud/cloud.cfg.d/90_dpkg.cfg"]
  }

  provisioner "shell" {
    inline = [
      "sudo systemctl enable qemu-guest-agent.service"
    ]
  }

  # Generate manifest for use in Terraform
  post-processor "manifest" {
    output      = "../../terraform/pve-ubuntu-2204-amd64-qemu.manifest.json"
    custom_data = {
      node = "${var.node_name}"
    }
    strip_path  = true
  }
}