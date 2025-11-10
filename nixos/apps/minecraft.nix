{config, ...}: let
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
    {
      slug = "all-the-mods-10";
      port = 25565;
      path = "ATM10";
    }
    {
      slug = "all-the-mods-10-sky";
      port = 25566;
      path = "ATM10tts";
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
      "shpeeVanilla" = {
        image = "ghcr.io/itzg/minecraft-server";
        pull = "newer";
        environment = {
          EULA = "TRUE";
          MAX_MEMORY = "16G";
          TYPE = "FABRIC";
          PACKWIZ_URL = "https://raw.githubusercontent.com/KGB33/homelab/refs/heads/main/nixos/apps/minecraft/shpeeVanilla/pack.toml";
        };
        ports = [
          "25567:25565"
          "24454:24454/udp"
        ];
        volumes = [
          "/home/kgb33/Minecraft/shpeeVanilla/:/data"
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
}
