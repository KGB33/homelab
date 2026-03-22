{self, ...}: {
  flake.modules.nixos.grafana = {...}: {
    services.grafana = {
      enable = true;
      settings = {
        server = {
          domain = "graf.kgb33.dev";
          http_addr = "127.0.0.1";
          http_port = 2324;
        };
      };
    };
  };

  perSystem = {pkgs, ...}: {
    checks.grafana = pkgs.testers.runNixOSTest {
      name = "grafana check";
      nodes.machine = {...}: {
        imports = with self.modules.nixos; [grafana];
      };
      testScript =
        # python
        ''
          machine.wait_for_unit("grafana")
          machine.wait_until_succeeds("curl -sf localhost:2324/api/health")
        '';
    };
  };
}
