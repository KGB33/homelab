# Homelab 

This repository contains the IaC definitions for my homelab. 
*Most* things I host are running in Kubernetes. More
detailed information can be found on my blog - specificity [this
series](https://blog.kgb33.dev/posts/2023-04-03-talosian-terriforming/) of
posts.

Everything else is managed by Ansible. 

# Tooling

Tooling - i.e. `kubectl`, `ansible-lint`, etc - is managed by Nix. With nix flakes
enabled run create the following `.envrc` if using `direnv`, or run `nix develop`.

```bash
export LOCALE_ARCHIVE=/usr/lib/locale/locale-archive
use flake
```

# Secrets 

Secrets are kept in-repo using Sealed Secrets (for k8s secrets) or 
SOPS (for all other secrets).
