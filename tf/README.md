# Terraform

Currently, each Proxmox host must have the "talos-amd64.iso" image in the
"local:iso/" storage.

Eventually, the version should be appened to the end of the image name (i.e. "talos-amd64-v1.2.3.iso").

# Secrets

Proxmox api keys are stored in `enc.envrc`, to use them:

```
sops -d enc.envrc > .envrc
direnv allow
```
