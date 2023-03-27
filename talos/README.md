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
And generate the cilium config:

```bash
 helm template cilium cilium/cilium \
    --version 1.13.1 --namespace kube-system \
    --set ipam.mode=kubernetes \
    --set kubeProxyReplacement=strict \
    --set k8sServiceHost="10.0.0.116" \
    --set k8sServicePort="6443" \
    --set=securityContext.capabilities.ciliumAgent="{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}" \
    --set=securityContext.capabilities.cleanCiliumState="{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}" \
    --set=cgroup.autoMount.enabled=false \
    --set=cgroup.hostRoot=/sys/fs/cgroup \
    --set hubble.listenAddress=":4244" \
    --set hubble.relay.enabled=true \
    --set hubble.ui.enabled=true > cilium.yaml
```

## Start the Control plane node

There is only one control plane node:
  - `teemo.kgb33.dev`
  - `10.0.0.116`

However, the commands used will allow more control plane nodes to be
added in the future.

Run `control.py`, then watch the tty in proxmox and wait for the node to
come back online before preceding.

## Start the worker nodes

Just like the control plane nodes, run `./workers.py` and wait for the nodes
to reboot and come back online in Proxmox.

## Bootstrap etcd

Next, run `talosctl --talosconfig talosconfig bootstrap`

Then grab the kubeconfig:

```
talosctl --talosconfig talosconfig kubeconfig
cp kubeconfig ~/.kube/config
```

## Install Cilium

Lastly, run `kubectl apply -f cilium.yaml && cilium status --wait`
