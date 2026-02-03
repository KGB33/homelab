# Networking


## Hickory DNS

The DNS server is Hickory; see `nixos/modules/services/hickory-dns.nix` for details.


## Legacy Networking

Networking config is defined at the host level (i.e. in `hosts/<HOSTNAME>`)
Eventually, this code duplication could be moved into `base/`.

Importantly, Both `hostXYZ` entries under `networking` are changed per-host.
Additionally, the link name and IP address in `matchConfig.Name` and
`networkConfig.Address` respectively also need to be changed per-host. 

```nix
{...}: {
  imports = [
    ../../base/configuration.nix
    ./disks.nix
  ];

  networking = {
    hostName = "ophiuchus";
    hostId = "e7ea22a6"; # `head -c4 /dev/urandom | od -A none -t x4`
  };

  systemd.network = {
    enable = true;
    netdevs = {
      "10-vlan9" = {
        netdevConfig = {
          Name = "vlan9";
          Kind = "vlan";
        };
        vlanConfig.Id = 9;
      };
    };
    networks = {
      "10-enp0s13f0u1" = {
        matchConfig.Name = "enp0s13f0u1";
        vlan = ["vlan9"];
        networkConfig.LinkLocalAddressing = "no";
        linkConfig.RequiredForOnline = "carrier";
      };

      "10-vlan9" = {
        matchConfig.Name = "vlan9";
        gateway = ["10.0.9.1"];
        networkConfig = {
          Address = "10.0.9.104/24";
        };
      };
    };
  };
}
```

