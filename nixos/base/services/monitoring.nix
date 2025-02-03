{config, ...}: {
  services.prometheus = {
    enable = true;
    globalConfig.scrape_interval = "10s";
    remoteWrite = [
      {
        url = with config.shared.monitoring.mimir; "http://${hostName}:${toString httpPort}/api/v1/push";
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

  services.promtail = {
    enable = true;
    configuration = {
      server = {
        http_listen_port = 28183;
        grpc_listen_port = 0;
      };
      positions.filename = "/tmp/promtail.positions.yaml";
      clients = [
        {
          url = with config.shared.monitoring.loki; "http://${hostName}:${toString httpPort}/loki/api/v1/push";
        }
      ];
      scrape_configs = [
        {
          job_name = "journal";
          journal = {
            max_age = "12h";
            labels = {
              job = "systemd-journal";
              host = config.networking.hostName;
            };
          };
          relabel_configs = [
            {
              source_labels = ["__journal__systemd_unit"];
              target_label = "unit";
            }
          ];
        }
      ];
    };
  };
}
