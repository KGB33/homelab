{
  config,
  lib,
  ...
}: let
  mkMinecraft = {
    slug,
    port,
    path,
  }: {
    image = "ghcr.io/itzg/minecraft-server";
    pull = "newer";
    environment = {
      MODPACK_PLATFORM = "AUTO_CURSEFORGE";
      CF_SLUG = slug;
      EULA = "TRUE";
      MAX_MEMORY = "28G";
    };
    environmentFiles = [
      config.sops.secrets.curseForgeToken.path
    ];
    ports = [
      "${toString port}:${toString port}"
    ];
    volumes = [
      "/home/kgb33/Minecraft/${path}/:/data"
    ];
  };
  packs = [
    # {
    #   slug = "all-the-mods-10";
    #   port = 25565;
    #   path = "ATM10";
    # }
    # {
    #   slug = "all-the-mods-10-sky";
    #   port = 25566;
    #   path = "ATM10tts";
    # }
    # {
    #   slug = "ftb-stoneblock-4";
    #   port = 25568;
    #   path = "Stoneblock4";
    # }
    {
      slug = "monifactory";
      port = 25569;
      path = "monifactory";
    }
  ];
in {
  networking.firewall.allowedTCPPorts = (map (p: p.port) packs) ++ [25567 24454];

  virtualisation.oci-containers.containers =
    builtins.listToAttrs (map (p: {
        name = p.slug;
        value = mkMinecraft p;
      })
      packs)
    // {
      "silasOrigins" = {
        image = "ghcr.io/itzg/minecraft-server";
        pull = "newer";
        environment = {
          EULA = "TRUE";
          VERSION = "1.20.1";
          MAX_MEMORY = "16G";
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
