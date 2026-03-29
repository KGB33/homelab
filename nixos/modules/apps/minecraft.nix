{
  inputs,
  self,
  lib,
  ...
}: let
  baseDirectory = "/srv/minecraft";
in {
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
        MODRINTH_PROJECTS = "cc-tweaked";
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
          volumes = ["${baseDirectory}/servers/silas-origins:/data"];
        };
      };
    }

    {
      nixos.minecraft-base = {
        config,
        lib,
        ...
      }: let
      in {
        imports = with self.modules.nixos; [podman];

        systemd.tmpfiles.rules = [
          "d ${baseDirectory} 0750 kgb33 kgb33 -"
          "d ${baseDirectory}/servers 0750 kgb33 kgb33 -"
        ];

        systemd.services =
          lib.mapAttrs'
          (name:
            lib.const (lib.nameValuePair "podman-${name}" {
              serviceConfig.Restart = lib.mkForce "always";
            }))
          (lib.filterAttrs (_: c: lib.hasPrefix "ghcr.io/itzg/minecraft-server" c.image)
            config.virtualisation.oci-containers.containers);
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
            assert "kgb33" in passwd

            packDir = machine.succeed("stat /srv/minecraft")
            assert "Access: (0750/drwxr-x---)  Uid: (  998/kgb33)   Gid: (  998/kgb33)" in packDir

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
