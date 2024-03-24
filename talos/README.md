# Talos VMs

This directory iscludes all the information, scrips and resoures
needed to provision a fresh, cilium enabled cluster on talos VMs.

## Creating the VMs

TLDR: Run `terraform apply` in the neighboring `tf` folder.
More information is located in that folder.

## Generating the Config files

Use the following command to create `talosconfig`, `controlplane.yaml` and `worker.yaml`

```bash
talosctl gen config \
    home https://10.0.0.116:6443 \
    --config-patch '[{"op": "add", "path": "/cluster/proxy", "value": {"disabled": true}}, {"op":"add", "path": "/cluster/network/cni", "value": {"name": "none"}}]'

talosctl --talosconfig talosconfig config endpoint 10.0.0.116
talosctl --talosconfig talosconfig config node 10.0.0.116
```

## Daggerized Provsioning

Run each of the dagger functions in order, waiting for the nodes to come back online after each one:

```
$ dagger functions
argocd      Step 4: Start ArgoCD.
base-img    Builds a Alpine image with talosctl installed and ready to go.
bootstrap   Step 2: Bootstrap etcd.
cilium      Step 3: Apply Cilium.
provision   Step 1: Provision the nodes.
```
