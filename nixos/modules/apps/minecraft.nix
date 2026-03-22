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

    {
      nixos.minecraft-base = {...}: let
        baseDirectory = "/srv/minecraft";
      in {
        imports = with self.modules.nixos; [podman];

        systemd.tmpfiles.rules = [
          "d ${baseDirectory} 0750 minecraft-runner minecraft-runner -"
        ];

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
