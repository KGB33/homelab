# Proxmox VMs

Download the latest Talos ISO onto all the Proxmox nodes
[https://github.com/siderolabs/talos/releases/latest/download/metal-amd64.iso](https://github.com/siderolabs/talos/releases/latest/download/metal-amd64.iso)
Make sure to save it as `talos-metal-amd64.iso`.

# Create a Terraform User

Following the instructions on the [Telmate/proxmox docs](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs).

Or ssh to a node and run the following commands:


```bash
# Create Role
pveum role add TerraformProv -privs "Datastore.AllocateSpace Datastore.Audit Pool.Allocate Sys.Audit Sys.Console Sys.Modify VM.Allocate VM.Audit VM.Clone VM.Config.CDROM VM.Config.Cloudinit VM.Config.CPU VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Migrate VM.Monitor VM.PowerMgmt SDN.Use"
# Create User (No password)
pveum user add terraform-prov@pve
# Add Role to User
pveum aclmod / -user terraform-prov@pve -role TerraformProv
```

# Create Proxmox API Token

Then, open the Web UI to generate the API Key.

Go to Datacenter → Permissions → API Tokens; then Add a token. 
Expose the Token ID (public) and Secret (duh) as environment variables:

```bash
# Examples from Telmate Docs
export PM_API_TOKEN_ID="terraform-prov@pve!mytoken"
export PM_API_TOKEN_SECRET="afcd8f45-acc1-4d0f-bb12-a70b0777ec11"
```

# Build VMs

```bash
cd tf
tofu apply
```
