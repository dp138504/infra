packer {
  required_plugins {
    proxmox = {
      version = " >= 1.1.0"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

variable "proxmox_api_url" {
    type = string
    default = "https://odin-pve.crossfits.dpitts.us/api2/json"
}

variable "proxmox_api_token_id" {
    type = string
    default = "root@pam!pakcer"
}

variable "proxmox_api_token_secret" {
    type = string
    sensitive = true
}

variable "ssh_packer_password" {
    type = string
    sensitive = true
}

source "proxmox" "rocky-9-rke2-server" {
    proxmox_url = "${var.proxmox_api_url}"
    username = "${var.proxmox_api_token_id}"
    token = "${var.proxmox_api_token_secret}"

    
    # VM General Settings
    node = "thor-pve"
    vm_id = "1000"
    vm_name = "rocky-9-rke2-server"
    template_description = "Rocky Linux 9 Template - RKE2 Server"
    os = "l26"

    # VM OS Settings
    # (Option 1) Local ISO File
    iso_file = "crossfits-cephfs:iso/Rocky-9.1-x86_64-boot.iso"
    # - or -
    # (Option 2) Download ISO
    #iso_url = "https://download.rockylinux.org/pub/rocky/9/isos/x86_64/Rocky-9.1-x86_64-boot.iso"
    #iso_checksum = "a36753d0efbea2f54a3dc7bfaa4dba95efe9aa3d6af331d5c5b147ea91240c21"
    iso_storage_pool = "crossfits-cephfs"
    unmount_iso = true

    # VM System Settings
    qemu_agent = true

    # VM Hard Disk Settings
    scsi_controller = "virtio-scsi-single"

    disks {
        disk_size = "50G"
        format = "raw"
        storage_pool = "crossfits-ec"
        storage_pool_type = "rbd"
        type = "virtio"
        io_thread = "true"
        cache_mode = "writeback"
    }

    # VM CPU Settings
    cores = "4"
    cpu_type = "host"

    
    # VM Memory Settings
    memory = "16384" 

    # VM Network Settings
    network_adapters {
        model = "virtio"
        bridge = "vmbr0"
        firewall = "false"
        packet_queues = "4"
    } 

    # VM Cloud-Init Settings
    cloud_init = true
    cloud_init_storage_pool = "crossfits-cephfs"

    # PACKER Boot Commands
    boot_command = ["<tab><end><bs><bs><bs><bs><bs>inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg<enter>"]
    #boot = "c"
    boot_wait = "5s"

    # PACKER Autoinstall Settings
    http_directory = "rocky-9/http" 
    # (Optional) Bind IP Address and Port
    http_bind_address = "0.0.0.0"
    http_port_min = 8802
    http_port_max = 8802

    ssh_username = "packer"

    # (Option 1) Add your Password here
    ssh_password = "${var.ssh_packer_password}"
    # - or -
    # (Option 2) Add your Private SSH KEY file here
    #ssh_private_key_file = "/home/dap/.ssh/id_ed25519.vms"

    # Raise the timeout, when installation takes longer
    ssh_timeout = "20m"
}

build {
    name = "rocky-9-rke2-server"
    sources = ["source.proxmox.rocky-9-rke2-server"]

    provisioner "shell" {
        execute_command = "echo ${var.ssh_packer_password} | sudo -S sh -c '{{ .Vars }} {{ .Path }}'"
        inline = [
            "rm /etc/ssh/ssh_host_*",
            "truncate -s 0 /etc/machine-id",
            "dnf -y autoremove",
            "dnf -y clean all",
            "cloud-init clean",
            "sync"
        ]
    }

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #2
    provisioner "file" {
        source = "rocky-9/files/99-pve.cfg"
        destination = "/tmp/99-pve.cfg"
    }

    provisioner "file" {
        source = "rocky-9/files/rke2-canal.conf"
        destination = "/tmp/rke2-canal.conf"
    }

    provisioner "file" {
        source = "rocky-9/files/server-config.yml"
        destination = "/tmp/config.yaml"
    }

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #3
    provisioner "shell" {
        execute_command = "echo ${var.ssh_packer_password} | sudo -S sh -c '{{ .Vars }} {{ .Path }}'"
        inline = [ 
            "cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg",
            "cp /tmp/rke2-canal.conf /etc/NetworkManager/conf.d/rke2-canal.conf" # https://docs.rke2.io/known_issues#networkmanager
        ]
    }

    provisioner "shell" {
        execute_command = "echo ${var.ssh_packer_password} | sudo -S sh -c '{{ .Vars }} {{ .Path }}'"
        inline = [
            "curl -sfL https://get.rke2.io | sh -",
            "systemctl enable rke2-server.service",
            "useradd --system --shell /sbin/nologin --no-create-home --user-group etcd",
            "sudo cp -f /usr/share/rke2/rke2-cis-sysctl.conf /etc/sysctl.d/60-rke2-cis.conf",
            "cp /tmp/config.yaml /etc/rancher/rke2/config.yaml"
        ]
    }
}