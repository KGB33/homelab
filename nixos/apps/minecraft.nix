{ den, ... }:
let
  minecraft-server =
    {
      slug,
      ports,
      extraEnv,
    }:
    {
      includes = with den.aspects; [
        minecraft-base
        sops
      ];

      nixos = { config, ... }: {
        networking.firewall.allowedTCPPorts = ports;

        sops.secrets = {
          curseForgeToken = {
            sopsFile = ../../secrets/curseForgeSecrets.env;
            format = "dotenv";
            restartUnits = [
              config.virtualisation.oci-containers.containers."minecraft-server-${slug}".serviceName
            ];
          };
        };

        virtualisation.oci-containers.containers."minecraft-server-${slug}" = {
          image = "ghcr.io/itzg/minecraft-server";
          pull = "newer";
          environment = {
            EULA = "TRUE";
            MAX_MEMORY = "16G";
          }
          // extraEnv;
          environmentFiles = [
            config.sops.secrets.curseForgeToken.path
          ];
          ports = map (p: "${toString p}:${toString p}") ports;
          volumes = [
            "/home/kgb33/Minecraft/${slug}/:/data"
          ];
        };
      };
    };
in
{
  den.aspects.minecraft-base = {
    includes = with den.aspects; [ podman ];

    nixos =
      {
        config,
        lib,
        ...
      }:
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
                _: c: lib.hasPrefix "ghcr.io/itzg/minecraft-server" c.image
              ) config.virtualisation.oci-containers.containers
            );
      };
  };

  den.aspects.minecraft-ftb-evolution = minecraft-server {
    slug = "ftb-evolution";
    ports = [ 25568 ];
    extraEnv = {
      MODPACK_PLATFORM = "AUTO_CURSEFORGE";
      MAX_MEMORY = "28G";
      CF_SLUG = "ftb-evolution";
      CF_FILE_ID = "100476"; # Pin to 1.43.0, 1.43.1 will not launch
    };
  };

  den.aspects.minecraft-monifactory = minecraft-server {
    slug = "monifactory";
    ports = [ 25569 ];
    extraEnv = {
      MODPACK_PLATFORM = "AUTO_CURSEFORGE";
      CF_SLUG = "monifactory";
      MODRINTH_PROJECTS = "cc-tweaked";
    };
  };

  # Only used by the `minecraft-server` check below.
  den.aspects.minecraft-vanilla = minecraft-server {
    slug = "vanilla";
    ports = [ 25565 ];
    extraEnv = {
      TYPE = "VANILLA";
    };
  };

  den.hosts.x86_64-linux = {
    check-minecraft-base = {
      intoAttr = [ ];
      aspect = den.aspects.minecraft-base;
    };
    check-minecraft-vanilla = {
      intoAttr = [ ];
      aspect = den.aspects.minecraft-vanilla;
    };
  };

  perSystem = { pkgs, ... }: {
    checks = {
      minecraft-base = pkgs.testers.runNixOSTest {
        name = "Base minecraft-server test";
        nodes.machine = den.hosts.x86_64-linux.check-minecraft-base.mainModule;
        testScript =
          # python
          ''
            machine.succeed("podman info");
          '';
      };
      minecraft-server = pkgs.testers.runNixOSTest {
        name = "Simple server test";
        nodes.machine = den.hosts.x86_64-linux.check-minecraft-vanilla.mainModule;
        testScript =
          # python
          ''
            print("Non-networked machines cannot download docker container or MC server")
            print("This test is only usable in interactive mode")
          '';
      };
    };
  };
}
