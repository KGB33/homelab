{
  sops,
  config,
  pkgs,
  ...
}: {
  imports = [
    ../../base/configuration.nix
    ./disks.nix
  ];

  networking = {
    hostName = "ophiuchus";
    hostId = "e7ea22a6"; # `head -c4 /dev/urandom | od -A none -t x4`
    firewall = {
      allowedTCPPorts = [
        443 # Caddy Reverse Proxy
        9090 # Prometheus
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

  sops = {
    secrets = {
      "DISCORD_TOKEN" = {
        sopsFile = ./roboShpeeSecrets.env;
        format = "dotenv";
        restartUnits = ["docker-roboShpee.service"];
      };
      "cloudflare_dns" = {
        sopsFile = ./cloudflareSecrets.env;
        format = "dotenv";
        restartUnits = ["caddy.service"];
      };
    };
  };

  virtualisation.oci-containers.containers = {
    roboShpee = {
      image = "ghcr.io/kgb33/roboshpee:latest";
      pull = "always";
      environmentFiles = [
        config.sops.secrets.DISCORD_TOKEN.path
      ];
    };
    blog = {
      image = "ghcr.io/kgb33/blog.kgb33.dev:latest";
      pull = "always";
      ports = ["1313:1313"];
    };
  };

  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = ["github.com/caddy-dns/cloudflare@v0.0.0-20240703190432-89f16b99c18e"];
      hash = "sha256-jCcSzenewQiW897GFHF9WAcVkGaS/oUu63crJu7AyyQ=";
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
        log_level = "error";
      };

      store_gateway.sharding_ring.replication_factor = 1;
    };
  };

  services.prometheus = {
    enable = true;
    globalConfig.scrape_interval = "10s";
    remoteWrite = [
      {
        url = "http://localhost:${toString config.services.mimir.configuration.server.http_listen_port}/api/v1/push";
        name = "mimir";
      }
    ];
    scrapeConfigs = [
      {
        job_name = "caddy";
        static_configs = [
          {
            targets = [
              "localhost:2019" # Caddy
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
}
