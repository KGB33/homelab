# GitOps

The machine configs are synced every minute using [`comin`](https://github.com/nlewo/comin).

To see the status:
  - On machine, use `comin status`
  - Prometheus metrics are exported on `<HOST_IP>:4343/metrics`

## Rebuilding 

Wait at most a minute for `comin` to pull and start a rebuild, or:

```bash
sudo nixos-rebuild switch --flake /var/lib/comin/repository/nixos#(hostname)
```

> Note: `comin` can be paused using `systemctl stop comin`.

## Testing

To test on one machine, ensure `branches.testing.name` is unset and push
changes to a branch named `testing-<HOSTNAME>`.

To test changes on all machines, set `branches.tesing.name` to the name of the
testing branch. 


```nix
{...}: {
  services.comin = {
    enable = true;
    flakeSubdirectory = "nixos";
    exporter = {
      openFirewall = true;
      port = 4243;
    };
    remotes = [
      {
        name = "origin";
        url = "https://github.com/KGB33/homelab.git";
        branches.main.name = "main";
        branches.testing.name = "nixos-is-the-new-proxmox";
      }
    ];
  };
}
```
