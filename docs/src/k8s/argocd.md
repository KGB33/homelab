# ArgoCD

`cd` into the Ansible folder and Install ArgoCD:

```bash
ansible-playbook playbooks/k8s/argo.yaml
```

# Argo Login

Grab the initial secret:

```bash
kubectl get secrets -n argocd \
  argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 --decode 
```

Port forward the Argo dashboard, then login with username `admin`.

```
kubectl port-forward -n argocd services/argocd-server 8080:80
```

> Note: This also forwards the Web GUI to [localhost:8080](http://localhost:8080)

```
argocd login localhost:8080
argocd account update-password
```

Once the password has been changed, delete the initial secret:

```
kubectl delete secret -n argocd argocd-initial-admin-secret
```


# Apps-of-Apps

Apply the meta definition:

```bash
kubectl apply -f k8s-apps/meta.yaml
```

And sync them:

```bash
argocd app sync argocd-meta
argocd app sync --project default
```

> Note, on fresh cluster all the secrets will need to be rolled. 
