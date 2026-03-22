{self, ...}: {
  flake.modules.nixos.tempo = {...}: {
    services.tempo = {
      enable = true;
      settings = {
        server = {
          http_listen_address = "0.0.0.0";
          http_listen_port = 9878;
          grpc_listen_address = "0.0.0.0";
          grpc_listen_port = 9879;
        };
        distributor.receivers.otlp.protocols = {
          grpc.endpoint = "0.0.0.0:9095";
          http.endpoint = "0.0.0.0:3031";
        };
        storage.trace = {
          backend = "local";
          local.path = "/tmp/tempo/blocks";
          wal.path = "/tmp/tempo/wal";
        };
      };
    };
  };

  perSystem = {pkgs, ...}: {
    checks.tempo = pkgs.testers.runNixOSTest {
      name = "tempo check";
      nodes.machine = {...}: {
        imports = with self.modules.nixos; [tempo];
      };
      testScript =
        # python
        ''
          machine.wait_for_unit("tempo")
          machine.wait_until_succeeds("curl -sf localhost:9878/ready")
        '';
    };
  };
}
