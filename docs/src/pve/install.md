# Proxmox Install

For the base install, use the latest ISO and follow the instructions. 
Installation values:

- IP/Hostname:
  - `10.0.9.101/24` / `glint.pve.kgb33.dev`
  - `10.0.9.102/24` / `targe.pve.kgb33.dev`
  - `10.0.9.103/24` / `sundance.pve.kgb33.dev`
- Email: `pve@kgb33.dev`

Afterward, implement the following post-install steps.

## VLAN Tagging

Unfortunately, there is no way to add VLAN tagging in the installation.
Instead, open a shell on the device and edit `/etc/network/interfaces`.

```diff
 auto lo
 iface lo inet loopback
 
 iface enp7s0f1 inet manual
 
-auto vmbr0
-iface vmbr0 inet static
+auto vmbr0.9
+iface vmbr0.9 inet static
         address 10.0.9.102/24
         gateway 10.0.9.1

+auto vmbr0
+iface vmbr0 inet manual
         bridge-ports enp7s0f1
         bridge-stp off
         bridge-fd 0
+        bridge-vlan-aware yes
+        bridge-vids 2-4094

 iface wlp0s20f3 inet manual
 
 
 source /etc/network/interfaces.d/*
```

Save and reload with `ifreload -a`.

## Clustering

Make sure to cluster the machines using Proxmox's builtin clustering system. 

On one machines (I prefer `targe`) create the cluster, then join the other machines using their web UI.

## Post-Install Ansible Playbooks

Create my user account and pull ssh keys:

```bash
cd ansible
ansible-playbook --limit=pve playbooks/audd/audd.yaml -k -u root
```

Then, run the following playbook to set the DNS servers and enable closing the
lid without shutting down the machine.

```bash
ansible-playbook --limit=pve playbooks/pve/system-services.yaml -k -u root
```
