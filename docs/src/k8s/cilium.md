# Cilium

Add the Helm repo:
```bash
helm repo add cilium https://helm.cilium.io/
```

Generate the cilium config:

```bash
 helm template cilium cilium/cilium \
    --version 1.15.1 --namespace kube-system \
    --set ipam.mode=kubernetes \
    --set kubeProxyReplacement=strict \
    --set k8sServiceHost="10.0.9.25" \
    --set k8sServicePort="6443" \
    --set=securityContext.capabilities.ciliumAgent="{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}" \
    --set=securityContext.capabilities.cleanCiliumState="{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}" \
    --set=cgroup.autoMount.enabled=false \
    --set=cgroup.hostRoot=/sys/fs/cgroup \
    --set hubble.listenAddress=":4244" \
    --set hubble.relay.enabled=true \
    --set hubble.ui.enabled=true > cilium.yaml
```

And apply via, 
```bash
kubectl apply -f cilium.yaml && cilium status --wait
```
