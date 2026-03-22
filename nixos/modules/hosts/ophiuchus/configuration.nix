{inputs, ...}: {
  flake.modules.nixos.ophiuchus = {config, pkgs, ...}: {
    imports = with inputs.self.modules.nixos; [
      system-default
      sops
      roboshpee
      mealie
      loki
      mimir
      tempo
      grafana
      caddy
    ];

    networking = {
      hostName = "ophiuchus";
      hostId = "e7ea22a6";
      useNetworkd = true;
    };

    systemd.network = {
      enable = true;
      netdevs."10-vlan9" = {
        netdevConfig = {Name = "vlan9"; Kind = "vlan";};
        vlanConfig.Id = 9;
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
          networkConfig.Address = "10.0.9.104/24";
        };
      };
    };

  };
}
