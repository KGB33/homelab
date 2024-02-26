# TLS Certificates

## ACME Accounts

Create two ACME 'accounts' using the Web UI (Datacenter → ACME) or by SSH to
one of the Proxmox machines (make sure to `su` into `root`).

```bash
# Select option 1: "Let's Encrypt V2 Staging"
pvenode acme account register homelab-staging pve@kgb33.dev

# Select option 0: "Let's Encrypt V2"
pvenode acme account register homelab-prod pve@kgb33.dev
```

## `dns-01` Challenge

In the Web UI, create a new Challenge Plugin (Datacenter → ACME) with the
following values (all others are blank):

- Plugin ID: `homelab-cloudflare`
- DNS API: `Cloudflare Managed DNS`
- CF_TOKEN: `<CLOUDFLARE API TOKEN>`

## Add Certificate

On each node, navigate to System → Certificates and Add a domain under ACME.

- Challenge Type: `DNS`
- Plugin: `homelab-cloudflare` (The one made above)
- Domain: `<NODE>.pve.kgb33.dev`

Set the "Using Account", then click "Order Certificates Now".


### [Proxmox Docs](https://pve.proxmox.com/wiki/Certificate_Management)
