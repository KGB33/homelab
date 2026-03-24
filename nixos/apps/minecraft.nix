{
  config,
  lib,
  ...
}: {
  networking.firewall.allowedTCPPorts = [25565 25566 25568 25569 25567 24454];

  virtualisation.oci-containers.containers = {
    # "all-the-mods-10" = {
    #   image = "ghcr.io/itzg/minecraft-server";
    #   pull = "newer";
    #   environment = {
    #     MODPACK_PLATFORM = "AUTO_CURSEFORGE";
    #     CF_SLUG = "all-the-mods-10";
    #     EULA = "TRUE";
    #     MAX_MEMORY = "28G";
    #   };
    #   environmentFiles = [
    #     config.sops.secrets.curseForgeToken.path
    #   ];
    #   ports = ["25565:25565"];
    #   volumes = ["/home/kgb33/Minecraft/ATM10/:/data"];
    # };

    # "all-the-mods-10-sky" = {
    #   image = "ghcr.io/itzg/minecraft-server";
    #   pull = "newer";
    #   environment = {
    #     MODPACK_PLATFORM = "AUTO_CURSEFORGE";
    #     CF_SLUG = "all-the-mods-10-sky";
    #     EULA = "TRUE";
    #     MAX_MEMORY = "28G";
    #   };
    #   environmentFiles = [
    #     config.sops.secrets.curseForgeToken.path
    #   ];
    #   ports = ["25566:25566"];
    #   volumes = ["/home/kgb33/Minecraft/ATM10tts/:/data"];
    # };

    # "ftb-stoneblock-4" = {
    #   image = "ghcr.io/itzg/minecraft-server";
    #   pull = "newer";
    #   environment = {
    #     MODPACK_PLATFORM = "AUTO_CURSEFORGE";
    #     CF_SLUG = "ftb-stoneblock-4";
    #     EULA = "TRUE";
    #     MAX_MEMORY = "28G";
    #   };
    #   environmentFiles = [
    #     config.sops.secrets.curseForgeToken.path
    #   ];
    #   ports = ["25568:25568"];
    #   volumes = ["/home/kgb33/Minecraft/Stoneblock4/:/data"];
    # };

    "monifactory" = {
      image = "ghcr.io/itzg/minecraft-server";
      pull = "newer";
      environment = {
        MODPACK_PLATFORM = "AUTO_CURSEFORGE";
        CF_SLUG = "monifactory";
        EULA = "TRUE";
        MAX_MEMORY = "28G";
        MODRINTH_PROJECTS = "cc-tweaked";
      };
      environmentFiles = [
        config.sops.secrets.curseForgeToken.path
      ];
      ports = ["25569:25569"];
      volumes = ["/home/kgb33/Minecraft/monifactory/:/data"];
    };

    "silasOrigins" = {
      image = "ghcr.io/itzg/minecraft-server";
      pull = "newer";
      environment = {
        EULA = "TRUE";
        VERSION = "1.20.1";
        MAX_MEMORY = "20G";
        TYPE = "FORGE";
        PACKWIZ_URL = "https://raw.githubusercontent.com/FrostyTacos/SilasOriginsPack/refs/heads/main/pack.toml";
      };
      ports = [
        "25567:25565"
        "24454:24454/udp"
      ];
      volumes = [
        "/home/kgb33/Minecraft/SilasOrigins/:/data"
      ];
    };
  };

  sops = {
    secrets = {
      "curseForgeToken" = {
        sopsFile = ../secrets/curseForgeSecrets.env;
        format = "dotenv";
      };
    };
  };

  # Set Minecraft systemd services to restart always
  systemd.services =
    lib.mapAttrs'
    (name:
      lib.const (lib.nameValuePair "podman-${name}" {
        serviceConfig.Restart = lib.mkForce "always";
      }))
    (lib.filterAttrs (_: c: lib.hasPrefix "ghcr.io/itzg/minecraft-server" c.image)
      config.virtualisation.oci-containers.containers);
}
