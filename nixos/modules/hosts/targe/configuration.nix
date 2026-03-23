{inputs, ...}: {
  flake.modules.nixos.targe = {...}: {
    imports = with inputs.self.modules.nixos; [
      system-default
      wireguard
      hickory-dns
    ];

    networking = {
      hostName = "targe";
      hostId = "5768368a";
      useNetworkd = true;
    };

    systemd.network = {
      enable = true;
      netdevs."10-vlan9" = {
        netdevConfig = {
          Name = "vlan9";
          Kind = "vlan";
        };
        vlanConfig.Id = 9;
      };
      networks = {
        "10-enp" = {
          matchConfig.Name = "enp7s0f1";
          vlan = ["vlan9"];
          networkConfig.LinkLocalAddressing = "no";
          linkConfig.RequiredForOnline = "carrier";
        };
        "10-vlan9" = {
          matchConfig.Name = "vlan9";
          gateway = ["10.0.9.1"];
          addresses = [{Address = "10.0.9.102/24";}];
        };
      };
    };
  };
}
