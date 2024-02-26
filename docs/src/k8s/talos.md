# Talos

First, `cd` into the `talos` directory.

## Generating the Config files

Use the following command to create `talosconfig`, `controlplane.yaml` and `worker.yaml`

```bash
mkdir _out
pushd _out
talosctl gen config \
    home https://10.0.9.25:6443 \
    --config-patch '[{"op": "add", "path": "/cluster/proxy", "value": {"disabled": true}}, {"op":"add", "path": "/cluster/network/cni", "value": {"name": "none"}}]'

talosctl --talosconfig talosconfig config endpoint 10.0.9.25
talosctl --talosconfig talosconfig config node 10.0.9.25
popd
```

## Start Nodes

Create a Python virtual environment and install `dagger-io`.

```bash
python -m venv .venv
source .venv/bin/activate
pip install dagger-io 
```

Then run the playbook:

```bash
python pipeline.py
```

> TODO: Convert this to a Zenith style module.

## Bootstrap etcd

Next, run 
```bash
talosctl --talosconfig _out/talosconfig bootstrap
```

Then grab the kubeconfig, overwriting if needed:

```
talosctl --talosconfig _out/talosconfig kubeconfig
```

> Note: The nodes won't be healthy until the cilium config is applied in the next step!
