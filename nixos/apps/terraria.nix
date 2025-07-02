{config, ...}: {
  virtualisation.oci-containers.containers = {
    terraria = {
      image = "ghcr.io/passivelemon/terraria-docker:tmodloader-latest";
      pull = "newer";
      environment = {
        MAXPLAYERS = "12";
        MODPACK = "ShpeeVanilla";
        WORLDNAME = "Shpee";
        SECURE = "0";
      };
      environmentFiles = [
        config.sops.secrets.terrariaPassword.path
      ];
      ports = [
        "7777:7777"
      ];
      volumes = [
        "/home/kgb33/terraria/moddedShpeeVanilla/:/opt/terraria/config/"
      ];
    };
  };

  sops = {
    secrets = {
      "terrariaPassword" = {
        sopsFile = ../secrets/terrariaPassword.env;
        format = "dotenv";
        restartUnits = [
          config.virtualisation.oci-containers.containers.terraria.serviceName
        ];
      };
    };
  };
}
