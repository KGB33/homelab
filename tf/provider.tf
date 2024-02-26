terraform {
  required_version = "v1.6.2"
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.1-rc1"
    }
  }
}

provider "proxmox" {
  pm_api_url = "https://10.0.9.102:8006/api2/json"
  pm_timeout = 10000
}
