# Secrets 

Nix Secrets are managed by [sops-nix](https://github.com/Mic92/sops-nix).


Create a secret in-repo using `sops host/<HOSTNAME>/<SERVICE_NAME>Secret.[env/yaml/etc]`.

Import it into the config via:

```nix
{...}: {
sops = {
    secrets = {
      "SERVICE_NAME" = {
        sopsFile = ./SERVICE_NAME_Secrets.env;
        format = "dotenv";
      };
    };
  };
};
```

The private key must also be on the machine.

```bash
scp ~/.config/sops/age/keys.txt $HOSTNAME:~/.config/sops/age/keys.txt
```
