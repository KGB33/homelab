resource "proxmox_vm_qemu" "k8s-VMs" {
  for_each = {
    # Glint
    gnar = {
      ip      = "10.0.0.112",
      macaddr = "22:d4:92:84:f1:bb",
      id      = 501,
      node    = "glint"
    },
    gwen = {
      ip      = "10.0.0.113",
      macaddr = "22:d4:92:84:f1:cc",
      id      = 502,
      node    = "glint"
    },
    # Sundance
    sion = {
      ip      = "10.0.0.114",
      macaddr = "22:d4:92:84:f1:dd",
      id      = 503,
      node    = "sundance"
    },
    shen = {
      ip      = "10.0.0.115",
      macaddr = "22:d4:92:84:f1:ee",
      id      = 504,
      node    = "sundance"
    },
    # Targe
    teemo = {
      ip      = "10.0.0.116",
      macaddr = "22:d4:92:84:f1:ff",
      id      = 505,
      node    = "targe"
    },
    twitch = {
      ip      = "10.0.0.117",
      macaddr = "22:d4:92:84:f1:11",
      id      = 506,
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

  network {
    model   = "virtio"
    bridge  = "vmbr0"
    macaddr = each.value.macaddr
  }

  timeouts {
    create = "10m"
  }
}
