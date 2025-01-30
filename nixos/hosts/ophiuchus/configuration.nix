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
        http_addr = "localhost";
        http_port = 2324;
      };
    };
  };

  services.prometheus = {
    enable = true;
    globalConfig.scrape_interval = "10s";
    scrapeConfigs = [
      {
        job_name = "caddy";
        static_configs = [
          {
            targets = [
              "localhost:2019"
            ];
          }
        ];
      }
    ];
  };
}
