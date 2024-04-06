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
      memory = 12*1024
      sockets = 8
    },
    gwen = {
      ip        = "10.0.9.22",
      macaddr   = "22:d4:92:84:f1:cc",
      id        = 822,
      node      = "glint"
      size      = "16"
      ceph_size = "128"
      memory = 12*1024
      sockets = 8
    },
    # Sundance - doesn't have the RAM to handle ANY nodes.
    # sion = {
    #   ip        = "10.0.9.23",
    #   macaddr   = "22:d4:92:84:f1:dd",
    #   id        = 823,
    #   node      = "sundance"
    #   size      = "16"
    #   ceph_size = "128"
    #   memory = 4*1024
    #   sockets = 4
    # },
    # shen = { 
    #   ip      = "10.0.9.24",
    #   macaddr = "22:d4:92:84:f1:ee",
    #   id      = 824,
    #   node    = "sundance"
    # },
    # Targe
    teemo = { # Control Plane
      ip        = "10.0.9.25",
      macaddr   = "22:d4:92:84:f1:ff",
      id        = 825,
      node      = "targe"
      size      = "32"
      ceph_size = "128"
      memory = 4*1024
      sockets = 8
    },
    twitch = {
      ip        = "10.0.9.26",
      macaddr   = "22:d4:92:84:f1:11",
      id        = 826,
      node      = "targe"
      size      = "32"
      ceph_size = "128"
      memory = 12*1024
      sockets = 8
    },
    thresh = {
      ip        = "10.0.9.27",
      macaddr   = "22:d4:92:84:f1:22",
      id        = 827,
      node      = "targe"
      size      = "32"
      ceph_size = "128"
      memory = 12*1024
      sockets = 8
    }
    # Ophiuchus
    ornn = {
      ip        = "10.0.9.28",
      macaddr   = "22:d4:92:84:f1:33",
      id        = 828,
      node      = "ophiuchus"
      size      = "32"
      ceph_size = "128"
      memory = 12*1024
      sockets = 8
   },
   olaf = {
      ip        = "10.0.9.29",
      macaddr   = "22:d4:92:84:f1:44",
      id        = 829,
      node      = "ophiuchus"
      size      = "32"
      ceph_size = "128"
      memory = 12*1024
      sockets = 8
   },
   orianna = {
      ip        = "10.0.9.30",
      macaddr   = "22:d4:92:84:f1:55",
      id        = 830,
      node      = "ophiuchus"
      size      = "32"
      ceph_size = "128"
      memory = 12*1024
      sockets = 8
   }
}

  name        = "${each.key}.kgb33.dev"
  desc        = "K8s Node #1 \n ${each.key}.kgb33.dev \n IP: ${each.value.ip}"
  target_node = each.value.node
  iso         = "local:iso/talos-metal-amd64.iso"
  vmid        = each.value.id
  memory      = each.value.memory
  sockets     = each.value.sockets
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
