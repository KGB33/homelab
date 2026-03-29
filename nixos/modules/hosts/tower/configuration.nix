{inputs, ...}: {
  flake.modules.nixos.tower = {...}: {
    imports = with inputs.self.modules.nixos; [
      system-default
      minecraft-base
      minecraft-ftb-stoneblock-4
      minecraft-monifactory
      minecraft-silas-origins
    ];

    networking = {
      hostName = "tower";
      hostId = "fa635731";
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
          matchConfig.Name = "enp42s0";
          vlan = ["vlan9"];
          networkConfig.LinkLocalAddressing = "no";
          linkConfig.RequiredForOnline = "carrier";
        };
        "10-vlan9" = {
          matchConfig.Name = "vlan9";
          gateway = ["10.0.9.1"];
          networkConfig.Address = "10.0.9.100/24";
        };
      };
    };
  };
}
