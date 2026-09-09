{ den, ... }:
let
  image = "ghcr.io/community-valheim-tools/valheim-server:1.2.0";

  valheim-server =
    {
      slug,
      serverName,
      worldName,
      port ? 2456,
      extraEnv ? { },
    }:
    {
      includes = with den.aspects; [
        sops
        valheim-base
      ];

      nixos =
        { config, lib, ... }:
        let
          containerName = "valheim-server-${slug}";
          gamePorts = lib.range port (port + 2);
          passwordSecret = "${containerName}-password";
        in
        {
          networking.firewall.allowedUDPPorts = gamePorts;

          sops.secrets.${passwordSecret} = {
            sopsFile = ../../secrets/valheimPasswords.yaml;
            key = slug;
            restartUnits = [
              config.virtualisation.oci-containers.containers.${containerName}.serviceName
            ];
          };

          systemd.tmpfiles.rules = [
            "d /home/kgb33/Valheim/${slug}/config 0750 kgb33 users - -"
            "d /home/kgb33/Valheim/${slug}/data 0750 kgb33 users - -"
          ];

          virtualisation.oci-containers.containers.${containerName} = {
            inherit image;
            pull = "newer";
            capabilities.SYS_NICE = true;
            environment = {
              SERVER_NAME = serverName;
              SERVER_PORT = toString port;
              WORLD_NAME = worldName;
              SERVER_PASS_FILE = config.sops.secrets.${passwordSecret}.path;
              SERVER_PUBLIC = "false";
              BACKUPS = "true";
              BACKUPS_ZIP = "true";
            }
            // extraEnv;
            ports = map (p: "${toString p}:${toString p}/udp") gamePorts;
            volumes = [
              "/home/kgb33/Valheim/${slug}/config:/config"
              "/home/kgb33/Valheim/${slug}/data:/opt/valheim"
            ];
            extraOptions = [ "--stop-timeout=120" ];
          };
        };
    };
in
{
  den.aspects.valheim-base = {
    includes = [ den.aspects.podman ];

    nixos =
      { config, lib, ... }:
      {
        systemd.services =
          lib.mapAttrs'
            (
              name:
              lib.const (
                lib.nameValuePair "podman-${name}" {
                  serviceConfig.Restart = lib.mkForce "always";
                }
              )
            )
            (
              lib.filterAttrs (
                _: container: lib.hasPrefix image container.image
              ) config.virtualisation.oci-containers.containers
            );
      };
  };

  den.aspects.valheim-main = valheim-server {
    slug = "main";
    serverName = "Valheim";
    worldName = "Dedicated";
  };

  den.aspects.check-valheim-main = {
    includes = [ den.aspects.valheim-main ];

    nixos = {
      virtualisation.oci-containers.containers.valheim-server-main.autoStart = false;
    };
  };
}
