resource "proxmox_vm_qemu" "k8s-VMs" {
  for_each = {
    # Glint
    gnar = {
      ip        = "10.0.9.21",
      macaddr   = "22:d4:92:84:f1:bb",
      id        = 821,
      node      = "glint"
      size      = "16"
      ceph_size = "128"
    },
    gwen = {
      ip        = "10.0.9.22",
      macaddr   = "22:d4:92:84:f1:cc",
      id        = 822,
      node      = "glint"
      size      = "16"
      ceph_size = "128"
    },
    # Sundance
    sion = {
      ip        = "10.0.9.23",
      macaddr   = "22:d4:92:84:f1:dd",
      id        = 823,
      node      = "sundance"
      size      = "16"
      ceph_size = "128"
    },
    # shen = { # Sundance doesn't have the RAM to handle two nodes.
    #   ip      = "10.0.9.24",
    #   macaddr = "22:d4:92:84:f1:ee",
    #   id      = 824,
    #   node    = "sundance"
    # },
    # Targe
    teemo = {
      ip        = "10.0.9.25",
      macaddr   = "22:d4:92:84:f1:ff",
      id        = 825,
      node      = "targe"
      size      = "32"
      ceph_size = "128"
    },
    twitch = {
      ip        = "10.0.9.26",
      macaddr   = "22:d4:92:84:f1:11",
      id        = 826,
      node      = "targe"
      size      = "32"
      ceph_size = "128"
    }
  }

  name        = "${each.key}.kgb33.dev"
  desc        = "K8s Node #1 \n ${each.key}.kgb33.dev \n IP: ${each.value.ip}"
  target_node = each.value.node
  iso         = "local:iso/talos-metal-amd64.iso"
  vmid        = each.value.id
  memory      = 4096
  sockets     = 2
  scsihw      = "virtio-scsi-single"
  onboot      = true

  network {
    model   = "virtio"
    bridge  = "vmbr0"
    macaddr = each.value.macaddr
    tag     = 9
  }

  disks {
    scsi {
      scsi0 {
        disk {
          storage  = "local-lvm"
          size     = each.value.size
        }
      }
      scsi1 {
        disk {
          storage  = "local-lvm"
          size     = each.value.ceph_size
        }
      }
    }
  }
}
