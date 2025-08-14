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
  networking.firewall.allowedTCPPorts = map (p: p.port) packs;

  virtualisation.oci-containers.containers = builtins.listToAttrs (map (p: {
      name = p.slug;
      value = mkMinecraft p;
    })
    packs);

  sops = {
    secrets = {
      "curseForgeToken" = {
        sopsFile = ../secrets/curseForgeSecrets.env;
        format = "dotenv";
      };
    };
  };
}
