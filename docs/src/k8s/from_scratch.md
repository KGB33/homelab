# Starting from Scratch

First, make sure to create the Talos VMs as described [here](/pve/talos_vms.html),
then, `cd` into the `talos` directory.

From here, you can use Dagger to automatically provision the nodes. Each step
is also detailed in the sub-chapters - if you would prefer a manual approach.

```bash
$ dagger functions
Name        Description
argocd      Step 4: Start ArgoCD.
base-img    Builds a Alpine image with talosctl installed and ready to go.
bootstrap   Step 2: Bootstrap etcd.
cilium      Step 3: Apply Cilium.
provision   Step 1: Provision the nodes.
```

# Step 1: Provision the Nodes

After the brand new Talos VMs load up, run 

```bash
dagger call \
  --raw-template-file=./templates/talos.yaml.j2 \
  --talos-dir=_out \
  provision
```

# Step 2: Bootstrap Etcd

After all the nodes have rebooted (~1min), bootstrap Etcd.

```bash
dagger call \
  --raw-template-file=./templates/talos.yaml.j2 \
  --talos-dir=_out \
  bootstrap
```

# Step 3: Apply Cilium

Once Etcd has started, apply cilium:

```bash
dagger call \
  --raw-template-file=./templates/talos.yaml.j2 \
  --talos-dir=_out \
  cilium
```

# Step 4: Start ArgoCD

Once the Cilium step has compleated (it'll show a nice status dashboard), start ArgoCD.

```bash
dagger call \
  --raw-template-file=./templates/talos.yaml.j2 \
  --talos-dir=_out \
  argocd
```
Importantly, this step ends by  printing out the default ArgoCD password. **You
still need to manually change the password and sync the apps-of-apps; see
[here](/k8s/argocd.html).**
