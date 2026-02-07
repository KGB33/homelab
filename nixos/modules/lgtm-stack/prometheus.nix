{self, ...}: {
  flake.modules.nixos.prometheus = {config, ...}: {
    services.prometheus = {
      enable = true;
      globalConfig.scrape_interval = "10s";
      remoteWrite = [
        {
          url = "http://mimir.internal.kgb33.dev:9009/api/v1/push";
          name = "mimir";
        }
      ];
      scrapeConfigs = [
        {
          job_name = config.networking.hostName;
          static_configs = [
            {
              targets = [
                "localhost:${toString config.services.prometheus.exporters.node.port}"
              ];
            }
          ];
        }
      ];
      exporters = {
        node = {
          enable = true;
          enabledCollectors = ["systemd"];
        };
      };
    };
  };

  perSystem = {pkgs, ...}: {
    checks.prometheus = pkgs.testers.runNixOSTest {
      name = "prometheus exporter check";
      nodes.machine = {...}: {
        imports = with self.modules.nixos; [prometheus];
        environment.systemPackages = [pkgs.prometheus.cli ]; # For promtool
      };
      testScript =
        # python
        ''
        machine.wait_for_unit("prometheus")
        machine.succeed("promtool check healthy")
        machine.succeed("promtool check ready")
        '';
    };
  };
}
