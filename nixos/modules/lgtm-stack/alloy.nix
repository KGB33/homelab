{self, ...}: {
  flake.modules.nixos.alloy = {config, ...}: {
    services.alloy = {
      enable = true;
    };

    environment.etc = {
      "alloy/otelcol.alloy".text = ''
        otelcol.exporter.otlp "default" {
          client {
            endpoint = "http://alloy-ingest.internal.kgb33.dev:3031"
            tls { insecure = true }
          }
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

      "alloy/loki.alloy".text = ''
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
            url = "http://alloy-ingest.internal.kgb33.dev:3030/loki/api/v1/push"
          }
        }
      '';
    };
  };

  perSystem = {pkgs, ...}: {
    checks.alloy-ingest = pkgs.testers.runNixOSTest {
      name = "Alloy exporter check";
      nodes.machine = {...}: {
        imports = with self.modules.nixos; [alloy];
      };
      testScript =
        # python
        ''
          machine.wait_for_unit("alloy")
          machine.wait_for_open_port(12345)
          machine.succeed("curl localhost:12345/-/ready")
          machine.succeed("curl localhost:12345/-/healthy")
        '';
    };
  };
}
