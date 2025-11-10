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
  networking.firewall.allowedTCPPorts = (map (p: p.port) packs) ++ [25567];

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
          PLUGINS = ''
            https://modrinth.com/mod/zV5r3pPn
            https://modrinth.com/mod/Ax17wp3L
            https://modrinth.com/mod/lhGA9TYQ
            https://modrinth.com/mod/PFwYNrHb
            https://modrinth.com/mod/n6PXGAoM
            https://modrinth.com/mod/Wb5oqrBJ
            https://modrinth.com/mod/9s6osm5g
            https://modrinth.com/mod/e0M1UDsY
            https://modrinth.com/mod/UVtY3ZAC
            https://modrinth.com/mod/P7dR8mSH
            https://modrinth.com/mod/ohNO6lps
            https://modrinth.com/mod/XeEZ3fK2
            https://modrinth.com/mod/RnxjxXAI
            https://modrinth.com/mod/5ibSyLAz
            https://modrinth.com/mod/QD87oMUf
            https://modrinth.com/mod/iAiqcykM
            https://modrinth.com/mod/J81TRJWm
            https://modrinth.com/mod/L4pt5egz
            https://modrinth.com/mod/aC3cM3Vq
            https://modrinth.com/mod/aaRl8GiW
            https://modrinth.com/mod/QAGBst4M
            https://modrinth.com/mod/2M01OLQq
            https://modrinth.com/mod/UjXIyw47
            https://modrinth.com/mod/W1TjtEQz
            https://modrinth.com/mod/Eldc1g37
            https://modrinth.com/mod/qpPoAL6m
          '';
        };
        ports = [
          "25567:25567"
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
