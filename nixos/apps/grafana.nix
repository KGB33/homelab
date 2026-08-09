{ den, ... }: {
  den.aspects.grafana = {
    includes = with den.aspects; [ sops ];

    nixos = { config, ... }: {
      sops.secrets = {
        grafanaPassword = {
          sopsFile = ../../secrets/grafanaPassword;
          format = "binary";
          owner = "grafana";
          group = "grafana";
        };
      };

      services.grafana = {
        enable = true;
        settings = {
          security.secret_key = "$__file{${config.sops.secrets.grafanaPassword.path}}";
          server = {
            domain = "graf.kgb33.dev";
            http_addr = "127.0.0.1";
            http_port = 2324;
          };
        };
      };
    };
  };

  den.hosts.x86_64-linux.check-grafana = {
    intoAttr = [ ];
    aspect = den.aspects.grafana;
  };

  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    {
      checks.grafana = pkgs.testers.runNixOSTest {
        name = "grafana check";
        nodes.machine = {
          imports = [ den.hosts.x86_64-linux.check-grafana.mainModule ];

          services.grafana.settings.security.secret_key = lib.mkForce "123-noSopsInTest";
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
