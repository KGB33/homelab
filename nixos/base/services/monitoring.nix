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

  services.alloy = {
    enable = true;
  };

  environment.etc = {
    "alloy/otelcol.alloy".text = with config.shared.monitoring.tempo; ''
      otelcol.exporter.otlp "default" {
        client { endpoint = "http://${hostName}:${toString grpcPort}" }
      }

      otelcol.processor.batch "default" {
        output {
          metrics = [otelcol.exporter.otlp.default.input]
          logs    = [otelcol.exporter.otlp.default.input]
          traces  = [otelcol.exporter.otlp.default.input]
        }
      }

      otelcol.receiver.otlp "default" {
        output {
          metrics = [otelcol.processor.batch.default.input]
          logs    = [otelcol.processor.batch.default.input]
          traces  = [otelcol.processor.batch.default.input]
        }
        grpc { endpoint = "localhost:4317" }
        http { endpoint = "localhost:4318" }
      }
    '';

    "alloy/loki.alloy".text = with config.shared.monitoring.loki; ''
      loki.relabel "journal" {
        forward_to = []

        rule {
          source_labels = ["__journal__systemd_unit"]
          target_label = "unit"
        }
      }

      loki.source.journal "read" {
        forward_to = [loki.write.endpoint.receiver]
        relabel_rules = loki.relabel.journal.rules
        labels = {
          component = "loki.source.journal",
          host = "${config.networking.hostName}",
        }
      }

      loki.write "endpoint" {
        endpoint {
          url = "http://${hostName}:${toString httpPort}/loki/api/v1/push"
        }
      }
    '';
  };
}
