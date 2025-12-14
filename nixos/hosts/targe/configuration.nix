{config, ...}: let
  hostName = "targe";
in {
  imports = [
    ../../base/configuration.nix
    ./disks.nix
    ./blocky.nix
    ../../apps/wireguard.nix
  ];

  networking = {
    hostName = hostName;
    hostId = config.shared.hosts.${hostName}.hostId;
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
      "10-enp" = {
        matchConfig.Name = "enp7s0f1";
        vlan = ["vlan9"];
        networkConfig.LinkLocalAddressing = "no";
        linkConfig.RequiredForOnline = "carrier";
      };

      "10-vlan9" = {
        matchConfig.Name = "vlan9";
        gateway = ["10.0.9.1"];
        addresses = [
          {
            Address = with config.shared.hosts.${hostName}; "${ipv4}/${ipv4Mask}";
          }
          {
            # For Blocky to bind to.
            Address = "10.0.9.53/24";
          }
        ];
      };
    };
  };
}
