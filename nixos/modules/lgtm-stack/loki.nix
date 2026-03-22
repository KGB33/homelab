{self, ...}: {
  flake.modules.nixos.loki = {...}: {
    services.loki = {
      enable = true;
      configuration = let
        lokiDir = "/tmp/loki";
      in {
        server = {
          http_listen_address = "0.0.0.0";
          http_listen_port = 3030;
          grpc_listen_port = 9096;
          grpc_listen_address = "0.0.0.0";
        };
        auth_enabled = false;

        common = {
          path_prefix = lokiDir;
          replication_factor = 1;
          ring = {
            instance_addr = "127.0.0.1";
            kvstore.store = "inmemory";
            replication_factor = 1;
          };
        };
        schema_config = {
          configs = [
            {
              from = "2025-01-01";
              store = "tsdb";
              object_store = "filesystem";
              schema = "v13";
              index = {
                prefix = "index_";
                period = "24h";
              };
            }
          ];
        };
        storage_config.filesystem.directory = "${lokiDir}/chunks";
        compactor = {
          working_directory = "${lokiDir}/compactor";
        };
      };
    };
  };

  perSystem = {pkgs, ...}: {
    checks.loki = pkgs.testers.runNixOSTest {
      name = "loki check";
      nodes.machine = {...}: {
        imports = with self.modules.nixos; [loki];
      };
      testScript =
        # python
        ''
          machine.wait_for_unit("loki")
          machine.wait_until_succeeds("curl -sf localhost:3030/ready")
        '';
    };
  };
}
