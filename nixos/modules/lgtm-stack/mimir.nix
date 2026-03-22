{self, ...}: {
  flake.modules.nixos.mimir = {...}: {
    services.mimir = {
      enable = true;
      configuration = {
        multitenancy_enabled = false;

        blocks_storage = {
          backend = "filesystem";
          bucket_store = {
            sync_dir = "/tmp/mimir/tsdb-sync";
          };
          filesystem = {
            dir = "/tmp/mimir/data/tsdb";
          };
          tsdb = {
            dir = "/tmp/mimir/tsdb";
          };
        };

        compactor = {
          data_dir = "/tmp/mimir/compactor";
          sharding_ring = {
            instance_addr = "127.0.0.1";
            kvstore.store = "memberlist";
          };
        };

        distributor.ring = {
          instance_addr = "127.0.0.1";
          kvstore.store = "memberlist";
        };

        ingester.ring = {
          instance_addr = "127.0.0.1";
          kvstore.store = "memberlist";
          replication_factor = 1;
        };

        ruler_storage = {
          backend = "filesystem";
          filesystem.dir = "/tmp/mimir/rules";
        };

        server = {
          http_listen_port = 9009;
          grpc_listen_port = 9097;
          log_level = "error";
        };

        store_gateway.sharding_ring.replication_factor = 1;
      };
    };
  };

  perSystem = {pkgs, ...}: {
    checks.mimir = pkgs.testers.runNixOSTest {
      name = "mimir check";
      nodes.machine = {...}: {
        imports = with self.modules.nixos; [mimir];
      };
      testScript =
        # python
        ''
          machine.wait_for_unit("mimir")
          machine.wait_until_succeeds("curl -sf localhost:9009/ready")
        '';
    };
  };
}
