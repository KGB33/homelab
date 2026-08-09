{
  den,
  inputs,
  ...
}:
{
  flake-file.inputs.roboshpee = {
    url = "github:KGB33/RoboShpee";
  };

  den.aspects.roboshpee = {
    includes = with den.aspects; [
      sops
      podman
    ];

    nixos = { config, ... }: {
      sops.secrets = {
        "DISCORD_TOKEN" = {
          sopsFile = ../../secrets/roboShpeeSecrets.env;
          format = "dotenv";
          restartUnits = [
            config.systemd.services.roboshpee.name
          ];
        };
      };

      systemd.services.roboshpee = {
        enable = true;
        wants = [ "network.target" ];
        serviceConfig = {
          ExecStart = "${inputs.roboshpee.packages.x86_64-linux.roboshpee}/bin/roboshpee";
          Type = "simple";
          Restart = "on-failure";
          EnvironmentFile = config.sops.secrets.DISCORD_TOKEN.path;
          Environment = "RUST_LOG=info";
        };
      };
    };
  };

  den.hosts.x86_64-linux.check-roboshpee = {
    intoAttr = [ ];
    aspect = den.aspects.roboshpee;
  };

  perSystem = { pkgs, ... }: {
    checks.roboshpee = pkgs.testers.runNixOSTest {
      name = "Basic RoboShpee test";
      nodes.machine = den.hosts.x86_64-linux.check-roboshpee.mainModule;
      testScript =
        # python
        ''
          machine.wait_for_file("/etc/systemd/system/roboshpee.service")
        '';
    };
  };
}
