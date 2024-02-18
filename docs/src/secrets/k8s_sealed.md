# Kubernetes Secrets

Application secrets are managed using [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets)
and are stored with the application deployment config in `k8s-apps/<APPLICATION>/<SEALED_SECRET>.yaml`.

## Creating/Rotating Secrets

I use the following zsh function to regenerate the sealed secret when rotating them. Importantly, 
editing the plain text values within seems to cause the decryption to fail within the cluster; so 
recreating the secret from scratch seems to be the most consistent.

```bash
function sealSecret() {
    if [[ $# -eq 0 ]]; then
        echo "Useage: sealSecret secretName secretValue namespace"
        return 1
    fi
    echo -n $2 | \
    kubectl create secret generic $1 --dry-run=client --from-file=$1=/dev/stdin -o yaml -n $3 | \
    kubeseal -o yaml
}
```

## Listing Application Secrets

Currently, there are three sealed secrets:

 - `k8s-apps/traefik/CloudflareSecret.yaml`
 - `k8s-apps/roboshpee/SealedToken.yaml`
 - `k8s-apps/pihole/pihole-admin-password.yaml`

 To get a current list of secrets in-repo:

```bash
rg -l '^kind: SealedSecret' k8s-apps
```

Or in-cluster:

```bash
kubectl get -A sealedsecrets.bitnami.com
```
