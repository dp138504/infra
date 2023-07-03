locals {
  packer_manifest = jsondecode(file("${path.module}/pve-ubuntu-2204-amd64-qemu.manifest.json"))
  node_name = [for build in local.packer_manifest.builds : build.custom_data.node]
  vm_id = [for build in local.packer_manifest.builds : build.artifact_id]
}

resource "proxmox_virtual_environment_file" "user-data-docker2" {
  content_type = "snippets"
  datastore_id = "crossfits-cephfs"
  node_name    = "odin-pve"

  source_raw {
    data = templatefile("${path.module}/templates/user-data.tftpl", {
      hostname = "docker2"
      packages = jsonencode(["docker.io", "docker-compose"])
    })
    file_name = "user-data-docker2"
  }
}

resource "proxmox_virtual_environment_file" "network-data-docker2" {
  content_type = "snippets"
  datastore_id = "crossfits-cephfs"
  node_name    = "odin-pve"

  source_raw {
    data = templatefile("${path.module}/templates/network-data.tftpl", { 
      dhcp = false,
      ip_address = "172.16.8.14",
      netmask = "16",
      gateway = "172.16.0.1",
      nameservers = jsonencode(["172.16.1.1", "172.16.0.1"]),
      search_domains = jsonencode(["crossfits.dpitts.us"])
    })
    file_name = "network-data-docker2"
  }
}

# Not sure why this wasn't in my terraform state. import is not supported by bgp's provider. Will migrate to k8s eventually.
# resource "proxmox_virtual_environment_vm" "docker2" {
#   name        = "docker2"
#   description = "Managed by Terraform"
#   tags        = ["terraform", "ubuntu2204", "docker", "lemmy"]

#   node_name = "odin-pve"
#   vm_id     = "107"

#   agent {
#     enabled = true
#   }

#   bios = "ovmf"

#   clone {
#     full      = true
#     vm_id     = local.vm_id[length(local.vm_id)-1] # Packer appends the latest build to the manifest file.
#     node_name = local.node_name[length(local.node_name)-1] # Packer appends the latest build to the manifest file.
#   }

#   disk {
#     datastore_id = "crossfits-ec"
#     discard      = "on"
#     file_format  = "raw"
#     interface    = "virtio0"
#     iothread     = true
#     size         = "50"
#     ssd          = true
#   }

#   initialization {
#     datastore_id         = "crossfits-ec"
#     user_data_file_id    = proxmox_virtual_environment_file.user-data-docker2.id
#     network_data_file_id = proxmox_virtual_environment_file.network-data-docker2.id
#   }
# }

##################################################
############### RKE Control Nodes ################
##################################################


#############33## RKE Control 1 ##################

resource "proxmox_virtual_environment_file" "user-data-rke-c1" {
  content_type = "snippets"
  datastore_id = "crossfits-cephfs"
  node_name    = "odin-pve"

  source_raw {
    data = templatefile("${path.module}/templates/user-data-rke.tftpl", {
      hostname = "rke-c1"
      packages = jsonencode(["docker.io"])
    })
    file_name = "user-data-rke-c1"
  }
}

resource "proxmox_virtual_environment_file" "network-data-rke-c1" {
  content_type = "snippets"
  datastore_id = "crossfits-cephfs"
  node_name    = "odin-pve"

  source_raw {
    data = templatefile("${path.module}/templates/network-data-rke.tftpl", { 
      dhcp = false,
      ip_address = "172.16.8.15",
      netmask = "16",
      gateway = "172.16.0.1",
      ip_address2 = "10.0.6.15",
      netmask2 = "24",
      nameservers = jsonencode(["172.16.1.1", "172.16.0.1"]),
      search_domains = jsonencode(["crossfits.dpitts.us"])
    })
    file_name = "network-data-rke-c1"
  }
}

resource "proxmox_virtual_environment_vm" "rke-c1" {
  name        = "rke-c1"
  description = "Managed by Terraform"
  tags        = ["terraform", "ubuntu2204", "k8s", "control"]

  node_name = "odin-pve"
  vm_id     = "210"

  agent {
    enabled = true
  }

  bios = "ovmf"

  clone {
    full      = true
    vm_id     = local.vm_id[length(local.vm_id)-1] # Packer appends the latest build to the manifest file.
    node_name = local.node_name[length(local.node_name)-1] # Packer appends the latest build to the manifest file.
  }

  disk {
    datastore_id = "crossfits-ec"
    discard      = "on"
    file_format  = "raw"
    interface    = "virtio0"
    iothread     = true
    size         = "50"
    ssd          = true
  }

  network_device {
    bridge = "vmbr0"
    enabled = true
    model = "virtio"
  }

  network_device {
    bridge = "vmbr1"
    enabled = true
    model = "virtio"
  }

  initialization {
    datastore_id         = "crossfits-ec"
    user_data_file_id    = proxmox_virtual_environment_file.user-data-rke-c1.id
    network_data_file_id = proxmox_virtual_environment_file.network-data-rke-c1.id
  }
}

################# RKE Control 2 ##################

resource "proxmox_virtual_environment_file" "user-data-rke-c2" {
  content_type = "snippets"
  datastore_id = "crossfits-cephfs"
  node_name    = "thor-pve"

  source_raw {
    data = templatefile("${path.module}/templates/user-data-rke.tftpl", {
      hostname = "rke-c2"
      packages = jsonencode(["docker.io"])
    })
    file_name = "user-data-rke-c2"
  }
}

resource "proxmox_virtual_environment_file" "network-data-rke-c2" {
  content_type = "snippets"
  datastore_id = "crossfits-cephfs"
  node_name    = "thor-pve"

  source_raw {
    data = templatefile("${path.module}/templates/network-data-rke.tftpl", { 
      dhcp = false,
      ip_address = "172.16.8.16",
      netmask = "16",
      gateway = "172.16.0.1",
      ip_address2 = "10.0.6.16",
      netmask2 = "24",
      nameservers = jsonencode(["172.16.1.1", "172.16.0.1"]),
      search_domains = jsonencode(["crossfits.dpitts.us"])
    })
    file_name = "network-data-rke-c2"
  }
}

resource "proxmox_virtual_environment_vm" "rke-c2" {
  name        = "rke-c2"
  description = "Managed by Terraform"
  tags        = ["terraform", "ubuntu2204", "k8s", "control"]

  node_name = "thor-pve"
  vm_id     = "211"

  agent {
    enabled = true
  }

  bios = "ovmf"

  clone {
    full      = true
    vm_id     = local.vm_id[length(local.vm_id)-1] # Packer appends the latest build to the manifest file.
    node_name = local.node_name[length(local.node_name)-1] # Packer appends the latest build to the manifest file.
  }

  disk {
    datastore_id = "crossfits-ec"
    discard      = "on"
    file_format  = "raw"
    interface    = "virtio0"
    iothread     = true
    size         = "50"
    ssd          = true
  }

  network_device {
    bridge = "vmbr0"
    enabled = true
    model = "virtio"
  }

  network_device {
    bridge = "vmbr1"
    enabled = true
    model = "virtio"
  }

  initialization {
    datastore_id         = "crossfits-ec"
    user_data_file_id    = proxmox_virtual_environment_file.user-data-rke-c2.id
    network_data_file_id = proxmox_virtual_environment_file.network-data-rke-c2.id
  }
}

################# RKE Control 3 ##################

resource "proxmox_virtual_environment_file" "user-data-rke-c3" {
  content_type = "snippets"
  datastore_id = "crossfits-cephfs"
  node_name    = "loki-pve"

  source_raw {
    data = templatefile("${path.module}/templates/user-data-rke.tftpl", {
      hostname = "rke-c3"
      packages = jsonencode(["docker.io"])
    })
    file_name = "user-data-rke-c3"
  }
}

resource "proxmox_virtual_environment_file" "network-data-rke-c3" {
  content_type = "snippets"
  datastore_id = "crossfits-cephfs"
  node_name    = "loki-pve"

  source_raw {
    data = templatefile("${path.module}/templates/network-data-rke.tftpl", { 
      dhcp = false,
      ip_address = "172.16.8.17",
      netmask = "16",
      gateway = "172.16.0.1",
      ip_address2 = "10.0.6.17",
      netmask2 = "24",
      nameservers = jsonencode(["172.16.1.1", "172.16.0.1"]),
      search_domains = jsonencode(["crossfits.dpitts.us"])
    })
    file_name = "network-data-rke-c3"
  }
}

resource "proxmox_virtual_environment_vm" "rke-c3" {
  name        = "rke-c3"
  description = "Managed by Terraform"
  tags        = ["terraform", "ubuntu2204", "k8s", "control"]

  node_name = "loki-pve"
  vm_id     = "212"

  agent {
    enabled = true
  }

  bios = "ovmf"

  clone {
    full      = true
    vm_id     = local.vm_id[length(local.vm_id)-1] # Packer appends the latest build to the manifest file.
    node_name = local.node_name[length(local.node_name)-1] # Packer appends the latest build to the manifest file.
  }

  disk {
    datastore_id = "crossfits-ec"
    discard      = "on"
    file_format  = "raw"
    interface    = "virtio0"
    iothread     = true
    size         = "50"
    ssd          = true
  }

  network_device {
    bridge = "vmbr0"
    enabled = true
    model = "virtio"
  }

  network_device {
    bridge = "vmbr1"
    enabled = true
    model = "virtio"
  }

  initialization {
    datastore_id         = "crossfits-ec"
    user_data_file_id    = proxmox_virtual_environment_file.user-data-rke-c3.id
    network_data_file_id = proxmox_virtual_environment_file.network-data-rke-c3.id
  }
}

##################################################
################ RKE Worker Nodes ################
##################################################

################# RKE Worker 1 ###################

resource "proxmox_virtual_environment_file" "user-data-rke-w1" {
  content_type = "snippets"
  datastore_id = "crossfits-cephfs"
  node_name    = "odin-pve"

  source_raw {
    data = templatefile("${path.module}/templates/user-data-rke.tftpl", {
      hostname = "rke-w1"
      packages = jsonencode(["docker.io"])
    })
    file_name = "user-data-rke-w1"
  }
}

resource "proxmox_virtual_environment_file" "network-data-rke-w1" {
  content_type = "snippets"
  datastore_id = "crossfits-cephfs"
  node_name    = "odin-pve"

  source_raw {
    data = templatefile("${path.module}/templates/network-data-rke.tftpl", { 
      dhcp = false,
      ip_address = "172.16.8.18",
      netmask = "16",
      gateway = "172.16.0.1",
      ip_address2 = "10.0.6.18",
      netmask2 = "24",
      nameservers = jsonencode(["172.16.1.1", "172.16.0.1"]),
      search_domains = jsonencode(["crossfits.dpitts.us"])
    })
    file_name = "network-data-rke-w1"
  }
}

resource "proxmox_virtual_environment_vm" "rke-w1" {
  name        = "rke-w1"
  description = "Managed by Terraform"
  tags        = ["terraform", "ubuntu2204", "k8s", "worker"]

  node_name = "odin-pve"
  vm_id     = "213"

  agent {
    enabled = true
  }

  bios = "ovmf"

  clone {
    full      = true
    vm_id     = local.vm_id[length(local.vm_id)-1] # Packer appends the latest build to the manifest file.
    node_name = local.node_name[length(local.node_name)-1] # Packer appends the latest build to the manifest file.
  }

  disk {
    datastore_id = "crossfits-ec"
    discard      = "on"
    file_format  = "raw"
    interface    = "virtio0"
    iothread     = true
    size         = "50"
    ssd          = true
  }

  network_device {
    bridge = "vmbr0"
    enabled = true
    model = "virtio"
  }

  network_device {
    bridge = "vmbr1"
    enabled = true
    model = "virtio"
  }

  initialization {
    datastore_id         = "crossfits-ec"
    user_data_file_id    = proxmox_virtual_environment_file.user-data-rke-w1.id
    network_data_file_id = proxmox_virtual_environment_file.network-data-rke-w1.id
  }
}

################# RKE Worker 2 ###################

resource "proxmox_virtual_environment_file" "user-data-rke-w2" {
  content_type = "snippets"
  datastore_id = "crossfits-cephfs"
  node_name    = "thor-pve"

  source_raw {
    data = templatefile("${path.module}/templates/user-data-rke.tftpl", {
      hostname = "rke-w2"
      packages = jsonencode(["docker.io"])
    })
    file_name = "user-data-rke-w2"
  }
}

resource "proxmox_virtual_environment_file" "network-data-rke-w2" {
  content_type = "snippets"
  datastore_id = "crossfits-cephfs"
  node_name    = "thor-pve"

  source_raw {
    data = templatefile("${path.module}/templates/network-data-rke.tftpl", { 
      dhcp = false,
      ip_address = "172.16.8.19",
      netmask = "16",
      gateway = "172.16.0.1",
      ip_address2 = "10.0.6.19",
      netmask2 = "24",
      nameservers = jsonencode(["172.16.1.1", "172.16.0.1"]),
      search_domains = jsonencode(["crossfits.dpitts.us"])
    })
    file_name = "network-data-rke-w2"
  }
}

resource "proxmox_virtual_environment_vm" "rke-w2" {
  name        = "rke-w2"
  description = "Managed by Terraform"
  tags        = ["terraform", "ubuntu2204", "k8s", "worker"]

  node_name = "thor-pve"
  vm_id     = "214"

  agent {
    enabled = true
  }

  bios = "ovmf"

  clone {
    full      = true
    vm_id     = local.vm_id[length(local.vm_id)-1] # Packer appends the latest build to the manifest file.
    node_name = local.node_name[length(local.node_name)-1] # Packer appends the latest build to the manifest file.
  }

  disk {
    datastore_id = "crossfits-ec"
    discard      = "on"
    file_format  = "raw"
    interface    = "virtio0"
    iothread     = true
    size         = "50"
    ssd          = true
  }

  network_device {
    bridge = "vmbr0"
    enabled = true
    model = "virtio"
  }

  network_device {
    bridge = "vmbr1"
    enabled = true
    model = "virtio"
  }

  initialization {
    datastore_id         = "crossfits-ec"
    user_data_file_id    = proxmox_virtual_environment_file.user-data-rke-w2.id
    network_data_file_id = proxmox_virtual_environment_file.network-data-rke-w2.id
  }
}

################# RKE Worker 3 ###################

resource "proxmox_virtual_environment_file" "user-data-rke-w3" {
  content_type = "snippets"
  datastore_id = "crossfits-cephfs"
  node_name    = "loki-pve"

  source_raw {
    data = templatefile("${path.module}/templates/user-data-rke.tftpl", {
      hostname = "rke-w3"
      packages = jsonencode(["docker.io"])
    })
    file_name = "user-data-rke-w3"
  }
}

resource "proxmox_virtual_environment_file" "network-data-rke-w3" {
  content_type = "snippets"
  datastore_id = "crossfits-cephfs"
  node_name    = "loki-pve"

  source_raw {
    data = templatefile("${path.module}/templates/network-data-rke.tftpl", { 
      dhcp = false,
      ip_address = "172.16.8.20",
      netmask = "16",
      gateway = "172.16.0.1",
      ip_address2 = "10.0.6.20",
      netmask2 = "24",
      nameservers = jsonencode(["172.16.1.1", "172.16.0.1"]),
      search_domains = jsonencode(["crossfits.dpitts.us"])
    })
    file_name = "network-data-rke-w3"
  }
}

resource "proxmox_virtual_environment_vm" "rke-w3" {
  name        = "rke-w3"
  description = "Managed by Terraform"
  tags        = ["terraform", "ubuntu2204", "k8s", "worker"]

  node_name = "loki-pve"
  vm_id     = "215"

  agent {
    enabled = true
  }

  bios = "ovmf"

  clone {
    full      = true
    vm_id     = local.vm_id[length(local.vm_id)-1] # Packer appends the latest build to the manifest file.
    node_name = local.node_name[length(local.node_name)-1] # Packer appends the latest build to the manifest file.
  }

  disk {
    datastore_id = "crossfits-ec"
    discard      = "on"
    file_format  = "raw"
    interface    = "virtio0"
    iothread     = true
    size         = "50"
    ssd          = true
  }

  network_device {
    bridge = "vmbr0"
    enabled = true
    model = "virtio"
  }

  network_device {
    bridge = "vmbr1"
    enabled = true
    model = "virtio"
  }

  initialization {
    datastore_id         = "crossfits-ec"
    user_data_file_id    = proxmox_virtual_environment_file.user-data-rke-w3.id
    network_data_file_id = proxmox_virtual_environment_file.network-data-rke-w3.id
  }
}

################# RKE Worker 4 ###################

resource "proxmox_virtual_environment_file" "user-data-rke-w4" {
  content_type = "snippets"
  datastore_id = "crossfits-cephfs"
  node_name    = "hela-pve"

  source_raw {
    data = templatefile("${path.module}/templates/user-data-rke.tftpl", {
      hostname = "rke-w4"
      packages = jsonencode(["docker.io"])
    })
    file_name = "user-data-rke-w4"
  }
}

resource "proxmox_virtual_environment_file" "network-data-rke-w4" {
  content_type = "snippets"
  datastore_id = "crossfits-cephfs"
  node_name    = "hela-pve"

  source_raw {
    data = templatefile("${path.module}/templates/network-data-rke.tftpl", { 
      dhcp = false,
      ip_address = "172.16.8.21",
      netmask = "16",
      gateway = "172.16.0.1",
      ip_address2 = "10.0.6.21",
      netmask2 = "24",
      nameservers = jsonencode(["172.16.1.1", "172.16.0.1"]),
      search_domains = jsonencode(["crossfits.dpitts.us"])
    })
    file_name = "network-data-rke-w4"
  }
}

resource "proxmox_virtual_environment_vm" "rke-w4" {
  name        = "rke-w4"
  description = "Managed by Terraform"
  tags        = ["terraform", "ubuntu2204", "k8s", "worker"]

  node_name = "hela-pve"
  vm_id     = "216"

  agent {
    enabled = true
  }

  bios = "ovmf"

  clone {
    full      = true
    vm_id     = local.vm_id[length(local.vm_id)-1] # Packer appends the latest build to the manifest file.
    node_name = local.node_name[length(local.node_name)-1] # Packer appends the latest build to the manifest file.
  }

  disk {
    datastore_id = "crossfits-ec"
    discard      = "on"
    file_format  = "raw"
    interface    = "virtio0"
    iothread     = true
    size         = "50"
    ssd          = true
  }

  network_device {
    bridge = "vmbr0"
    enabled = true
    model = "virtio"
  }

  network_device {
    bridge = "vmbr1"
    enabled = true
    model = "virtio"
  }

  initialization {
    datastore_id         = "crossfits-ec"
    user_data_file_id    = proxmox_virtual_environment_file.user-data-rke-w4.id
    network_data_file_id = proxmox_virtual_environment_file.network-data-rke-w4.id
  }
}

################# RKE Worker 5 ###################

resource "proxmox_virtual_environment_file" "user-data-rke-w5" {
  content_type = "snippets"
  datastore_id = "crossfits-cephfs"
  node_name    = "thor-pve"

  source_raw {
    data = templatefile("${path.module}/templates/user-data-rke.tftpl", {
      hostname = "rke-w5"
      packages = jsonencode(["docker.io"])
    })
    file_name = "user-data-rke-w5"
  }
}

resource "proxmox_virtual_environment_file" "network-data-rke-w5" {
  content_type = "snippets"
  datastore_id = "crossfits-cephfs"
  node_name    = "thor-pve"

  source_raw {
    data = templatefile("${path.module}/templates/network-data-rke.tftpl", { 
      dhcp = false,
      ip_address = "172.16.8.22",
      netmask = "16",
      gateway = "172.16.0.1",
      ip_address2 = "10.0.6.22",
      netmask2 = "24",
      nameservers = jsonencode(["172.16.1.1", "172.16.0.1"]),
      search_domains = jsonencode(["crossfits.dpitts.us"])
    })
    file_name = "network-data-rke-w5"
  }
}

resource "proxmox_virtual_environment_vm" "rke-w5" {
  name        = "rke-w5"
  description = "Managed by Terraform"
  tags        = ["terraform", "ubuntu2204", "k8s", "worker"]

  node_name = "thor-pve"
  vm_id     = "217"

  agent {
    enabled = true
  }

  bios = "ovmf"

  clone {
    full      = true
    vm_id     = local.vm_id[length(local.vm_id)-1] # Packer appends the latest build to the manifest file.
    node_name = local.node_name[length(local.node_name)-1] # Packer appends the latest build to the manifest file.
  }

  disk {
    datastore_id = "crossfits-ec"
    discard      = "on"
    file_format  = "raw"
    interface    = "virtio0"
    iothread     = true
    size         = "50"
    ssd          = true
  }

  network_device {
    bridge = "vmbr0"
    enabled = true
    model = "virtio"
  }

  network_device {
    bridge = "vmbr1"
    enabled = true
    model = "virtio"
  }
  initialization {
    datastore_id         = "crossfits-ec"
    user_data_file_id    = proxmox_virtual_environment_file.user-data-rke-w5.id
    network_data_file_id = proxmox_virtual_environment_file.network-data-rke-w5.id
  }
}