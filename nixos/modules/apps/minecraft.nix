{
  inputs,
  self,
  lib,
  ...
}: {
  flake.modules = lib.mkMerge [
    (self.factory.minecraft-server {
      slug = "ftb-stoneblock-4";
      ports = [25568];
      extraEnv = {
        MODPACK_PLATFORM = "AUTO_CURSEFORGE";
        CF_SLUG = "ftb-stoneblock-4";
      };
    })

    (self.factory.minecraft-server {
      slug = "monifactory";
      ports = [25569];
      extraEnv = {
        MODPACK_PLATFORM = "AUTO_CURSEFORGE";
        CF_SLUG = "monifactory";
        MAX_MEMORY = "28G";
      };
    })

    {
      nixos.minecraft-silas-origins = {config, ...}: {
        imports = with self.modules.nixos; [podman minecraft-base];

        networking.firewall = {
          allowedTCPPorts = [25567 24454];
          allowedUDPPorts = [24454];
        };

        virtualisation.oci-containers.containers.minecraft-silas-origins = {
          image = "ghcr.io/itzg/minecraft-server";
          pull = "newer";
          environment = {
            EULA = "TRUE";
            MAX_MEMORY = "20G";
            TYPE = "FORGE";
            VERSION = "1.20.1";
            PACKWIZ_URL = "https://raw.githubusercontent.com/FrostyTacos/SilasOriginsPack/refs/heads/main/pack.toml";
          };
          ports = ["25567:25565" "24454:24454/udp"];
          volumes = ["${config.users.users.minecraft-runner.home}/servers/silas-origins:/data"];
        };
      };
    }

    {
      nixos.minecraft-base = {
        config,
        lib,
        ...
      }: let
        baseDirectory = "/srv/minecraft";
      in {
        imports = with self.modules.nixos; [podman];

        systemd.tmpfiles.rules = [
          "d ${baseDirectory} 0750 minecraft-runner minecraft-runner -"
        ];

        systemd.services =
          lib.mapAttrs'
          (name:
            lib.const (lib.nameValuePair "podman-${name}" {
              serviceConfig.Restart = lib.mkForce "always";
            }))
          (lib.filterAttrs (_: c: lib.hasPrefix "ghcr.io/itzg/minecraft-server" c.image)
            config.virtualisation.oci-containers.containers);

        users = {
          groups.minecraft-runner = {};
          users.minecraft-runner = {
            isSystemUser = true;
            home = baseDirectory;
            description = "Minecraft server runner user";
            extraGroups = ["podman"];
            group = "minecraft-runner";
          };
        };
      };
    }
  ];

  perSystem = {pkgs, ...}: {
    checks = {
      minecraft-base = pkgs.testers.runNixOSTest {
        name = "Base minecraft-server test";
        nodes.machine = {...}: {
          imports = with self.modules.nixos; [minecraft-base];
        };
        testScript =
          # python
          ''
            passwd = machine.succeed("cat /etc/passwd")
            assert "minecraft-runner" in passwd

            packDir = machine.succeed("stat /srv/minecraft")
            assert "Access: (0750/drwxr-x---)  Uid: (  998/minecraft-runner)   Gid: (  998/minecraft-runner)" in packDir

            machine.succeed("podman info");
          '';
      };
      minecraft-server = pkgs.testers.runNixOSTest {
        name = "Simple server test";
        nodes.machine = {...}: {
          imports = [
            (self.factory.minecraft-server {
              slug = "vanilla";
              ports = [25565];
              extraEnv = {
                TYPE = "VANILLA";
              };
            }).nixos.minecraft-vanilla
          ];
        };
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
