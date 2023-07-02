resource "proxmox_vm_qemu" "k8s-VMs" {
  for_each = {
    # Glint
    gnar = {
      ip      = "10.0.8.115",
      macaddr = "22:d4:92:84:f1:bb",
      id      = 811,
      node    = "glint"
    },
    gwen = {
      ip      = "10.0.8.116",
      macaddr = "22:d4:92:84:f1:cc",
      id      = 812,
      node    = "glint"
    },
    # Sundance
    sion = {
      ip      = "10.0.8.117",
      macaddr = "22:d4:92:84:f1:dd",
      id      = 813,
      node    = "sundance"
    },
    shen = {
      ip      = "10.0.8.118",
      macaddr = "22:d4:92:84:f1:ee",
      id      = 814,
      node    = "sundance"
    },
    # Targe
    teemo = {
      ip      = "10.0.8.119",
      macaddr = "22:d4:92:84:f1:ff",
      id      = 815,
      node    = "targe"
    },
    twitch = {
      ip      = "10.0.8.120",
      macaddr = "22:d4:92:84:f1:11",
      id      = 816,
      node    = "targe"
    }
  }

  name        = "${each.key}.kgb33.dev"
  desc        = "K8s Node #1 \n ${each.key}.kgb33.dev \n IP: ${each.value.ip}"
  target_node = each.value.node
  iso         = "local:iso/talos-amd64.iso"
  vmid        = each.value.id
  memory      = 4096
  sockets     = 2
  scsihw      = "virtio-scsi-single"
  onboot      = true

  network {
    model   = "virtio"
    bridge  = "vmbr1"
    macaddr = each.value.macaddr
  }

  disk {
    type     = "scsi"
    storage  = "local-lvm"
    size     = "8G"
    iothread = 1
  }

  timeouts {
    create = "10m"
  }
}
