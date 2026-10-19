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
      otelcol
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

      services.opentelemetry-collector.settings = {
        receivers."otlp/roboshpee".protocols.http.endpoint = "127.0.0.1:4318";
        service.pipelines.traces = {
          receivers = [ "otlp/roboshpee" ];
          processors = [
            "memory_limiter"
            "resource/host"
            "batch"
          ];
          exporters = [ "otlp" ];
        };
      };

      systemd.services.roboshpee = {
        enable = true;
        wantedBy = [ "multi-user.target" ];
        wants = [ "network.target" ];
        environment = {
          RUST_LOG = "info";
          OTEL_EXPORTER_OTLP_TRACES_ENDPOINT = "http://127.0.0.1:4318/v1/traces";
        };
        serviceConfig = {
          ExecStart = "${inputs.roboshpee.packages.x86_64-linux.roboshpee}/bin/roboshpee";
          Type = "simple";
          Restart = "on-failure";
          EnvironmentFile = config.sops.secrets.DISCORD_TOKEN.path;
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
          machine.succeed("systemctl is-enabled roboshpee.service")
        '';
    };
  };
}
