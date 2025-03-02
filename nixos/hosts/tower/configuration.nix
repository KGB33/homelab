{...}: {
  imports = [
    ../../base/configuration.nix
    ./disks.nix
  ];

  networking = {
    hostName = "tower";
    hostId = "fa635731"; # `head -c4 /dev/urandom | od -A none -t x4`
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
        matchConfig.Name = "enp7s0f";
        vlan = ["vlan9"];
        networkConfig.LinkLocalAddressing = "no";
        linkConfig.RequiredForOnline = "carrier";
      };

      "10-vlan9" = {
        matchConfig.Name = "vlan9";
        gateway = ["10.0.9.1"];
        networkConfig = {
          Address = "10.0.9.100/24";
        };
      };
    };
  };

  virtualisation.oci-containers.containers = {
    minecraftCreate = {
      image = "library/hello-world";
      pull = "newer";
      environment = {
        EULA = "TRUE";
      };
      ports = [
        "25565:25565"
      ];
      volumes = [
        "/home/kgb33/Minecraft/create/:/data"
      ];
    };
  };
}
