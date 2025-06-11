{config, ...}: {
  imports = [
    ../../base/configuration.nix
    ../../apps/terraria.nix
    ./disks.nix
  ];

  networking = {
    hostName = "tower";
    hostId = "fa635731"; # `head -c4 /dev/urandom | od -A none -t x4`
    firewall = {
      allowedTCPPorts = [
        7777 # terraria
        25565 # minecraft
      ];
    };
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
        matchConfig.Name = "enp42s0";
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
      image = "ghcr.io/itzg/minecraft-server";
      pull = "newer";
      environment = {
        MODPACK_PLATFORM = "AUTO_CURSEFORGE";
        CF_MODPACK_ZIP = "/data/shpeeCreate.zip";
        CF_SLUG = "custom";
        EULA = "TRUE";
        MAX_MEMORY = "28G";
      };
      environmentFiles = [
        config.sops.secrets.curseForgeToken.path
      ];
      ports = [
        "25565:25565"
      ];
      volumes = [
        "/home/kgb33/Minecraft/create/:/data"
      ];
    };
  };

  sops = {
    secrets = {
      "curseForgeToken" = {
        sopsFile = ./curseForgeSecrets.env;
        format = "dotenv";
      };
    };
  };
}
