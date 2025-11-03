{
  config,
  pkgs,
  ...
}: {
  imports = [
    ../../base/configuration.nix
    ../../apps/roboshpee.nix
    ../../apps/mealie.nix
    ./disks.nix
  ];

  networking = {
    hostName = "ophiuchus";
    hostId = "e7ea22a6"; # `head -c4 /dev/urandom | od -A none -t x4`
    firewall = {
      allowedTCPPorts = [
        443 # Caddy Reverse Proxy
        9090 # Prometheus
        config.shared.monitoring.loki.httpPort
        config.shared.monitoring.loki.grpcPort
        config.shared.monitoring.mimir.httpPort
        config.shared.monitoring.mimir.grpcPort
        config.shared.monitoring.tempo.httpPort
        config.shared.monitoring.tempo.grpcPort
        config.shared.monitoring.tempo.serverGrpcPort
        config.shared.monitoring.tempo.serverHttpPort
      ];
    };
  };

  systemd.network = {
    enable = true;
    netdevs = {
      "10-vlan9" = {
        netdevConfig = {
          Name = "vlan9";
          Kind = "vlan";
        };
        vlanConfig.Id = 9;
      };
    };
    networks = {
      "10-enp0s13f0u1" = {
        matchConfig.Name = "enp0s13f0u1";
        vlan = ["vlan9"];
        networkConfig.LinkLocalAddressing = "no";
        linkConfig.RequiredForOnline = "carrier";
      };

      "10-vlan9" = {
        matchConfig.Name = "vlan9";
        gateway = ["10.0.9.1"];
        networkConfig = {
          Address = "10.0.9.104/24";
        };
      };
    };
  };

  sops.secrets = {
    "cloudflare_dns" = {
      sopsFile = ./cloudflareSecrets.env;
      format = "dotenv";
      restartUnits = ["caddy.service"];
    };
  };

  virtualisation.oci-containers.containers = {
    blog = {
      image = "ghcr.io/kgb33/blog.kgb33.dev:latest";
      pull = "newer";
      ports = ["1313:1313"];
    };
  };

  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = ["github.com/caddy-dns/cloudflare@v0.2.1"]; # Use git tag for version.
      hash = "sha256-AcWko5513hO8I0lvbCLqVbM1eWegAhoM0J0qXoWL/vI=";
    };
    environmentFile = config.sops.secrets.cloudflare_dns.path;
    globalConfig = ''
      admin

      metrics
    '';
    virtualHosts = let
      reverseProxy = port: ''
        reverse_proxy localhost:${toString port}

        tls {
          dns cloudflare {
            api_token {env.CF_API_TOKEN}
          }
        }
      '';
    in {
      "blog.kgb33.dev" = {
        extraConfig = reverseProxy 1313;
      };
      "${config.services.grafana.settings.server.domain}" = {
        extraConfig = reverseProxy config.services.grafana.settings.server.http_port;
      };
      "${config.virtualisation.oci-containers.containers.mealie.environment.BASE_URL}" = {
        extraConfig = reverseProxy 9925;
      };
    };
  };

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
        http_listen_port = config.shared.monitoring.mimir.httpPort;
        grpc_listen_port = config.shared.monitoring.mimir.grpcPort;
        log_level = "error";
      };

      store_gateway.sharding_ring.replication_factor = 1;
    };
  };

  services.prometheus = {
    # TODO: append caddy scrape config.
    scrapeConfigs = [
      {
        job_name = "caddy";
        static_configs = [
          {
            targets = [
              "localhost:2019" # Caddy
            ];
          }
        ];
      }
    ];
  };

  services.loki = {
    enable = true;
    configuration = let
      lokiDir = "/tmp/loki";
    in {
      server = with config.shared.monitoring.loki; {
        http_listen_address = "0.0.0.0";
        http_listen_port = httpPort;
        grpc_listen_port = grpcPort;
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

  services.tempo = {
    enable = true;
    settings = with config.shared.monitoring.tempo; {
      server = {
        http_listen_address = "0.0.0.0";
        http_listen_port = serverHttpPort;
        grpc_listen_address = "0.0.0.0";
        grpc_listen_port = serverGrpcPort;
      };
      distributor.receivers.otlp.protocols = {
        grpc.endpoint = "0.0.0.0:${builtins.toString grpcPort}";
        http.endpoint = "0.0.0.0:${builtins.toString httpPort}";
      };
      storage.trace = {
        backend = "local";
        local.path = "/tmp/tempo/blocks";
        wal.path = "/tmp/tempo/wal";
      };
    };
  };
}
