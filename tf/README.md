# Terraform


There is still a decent chunk of non-automated steps
to before the plan can run successfully.


## Creating The Templates

Create a VM, follow the Ubuntu server installer
(make sure to import your ssh keys). Once the server
has been booted for the first time install Ansible.

Tldr:
  - Follow Ubuntu Server installer.
  - (re)boot and install Ansible.

> A Note on Storage: Clone'd VMs need to be cloned to same
> storage as the original. So ether create a networked storage
> (i.e. ceph) or manually clone & migrate the template to
> each note.


## SSH Agent

I configured Terraform to use my ssh agent to connect to the
newly created VMs. However, if the key hasn't been imported
it will stall until eventually failing via timeout.
