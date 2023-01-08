terraform {
  required_version = "v1.3.7"
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "2.9.11"
    }
  }
}

provider "proxmox" {
  pm_api_url = "https://10.0.0.101:8006/api2/json"
  pm_timeout = 10000
}

resource "proxmox_vm_qemu" "cloudinit-test" {
  name        = "tftest1.kgb33.dev"
  desc        = "tf description"
  target_node = "glint"
  clone       = "ubuntu22.04-template"
  vmid        = 501
  memory      = 4096
  sockets     = 2
  scsihw      = "virtio-scsi-single"

  // TODO: Create Static IPs
  ipconfig0 = "ip=dhcp,gw=10.0.0.1"
  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  timeouts {
    create = "10m"
  }

  connection {
    # TODO: Static IPs (Again)
    host  = "10.0.0.112"
    type  = "ssh"
    user  = "kgb33"
    agent = true
  }

  provisioner "file" {
    source      = "./provisioners/highstate-template.yaml"
    destination = "highstate.yaml"
  }

  provisioner "remote-exec" {
    inline = [
      "ansible-playbook --connection=local --inventory 127.0.0.1, --limit 127.0.0.1 highstate.yaml -e 'ansible_become_password=${var.become_password}'",
      "hostname -f",
      "ip addr"
    ]
  }
}
