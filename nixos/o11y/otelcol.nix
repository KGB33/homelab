{ den, ... }:
{
  den.aspects.otelcol.nixos =
    { config, pkgs, ... }:
    {
      services.opentelemetry-collector = {
        enable = true;
        package = pkgs.opentelemetry-collector-contrib;
        validateConfigFile = true;
        settings = {
          receivers = {
            hostmetrics = {
              collection_interval = "30s";
              scrapers = {
                cpu = { };
                load = { };
                memory = { };
                paging = { };
                disk = { };
                filesystem = { };
                network = { };
                processes = { };
                system = { };
              };
            };

            journald = { };
          };

          processors = {
            memory_limiter = {
              check_interval = "1s";
              limit_mib = 128;
            };
            "resource/host".attributes = [
              {
                key = "host.name";
                value = config.networking.hostName;
                action = "upsert";
              }
            ];
            batch = { };
          };

          exporters.otlp = {
            endpoint = "signoz-ingest.internal.kgb33.dev:4317";
            sending_queue.storage = "file_storage";
          };

          extensions.file_storage = {
            directory = "/var/lib/opentelemetry-collector/export-queue";
            create_directory = true;
          };

          service = {
            extensions = [ "file_storage" ];
            pipelines = {
              metrics = {
                receivers = [ "hostmetrics" ];
                processors = [
                  "memory_limiter"
                  "resource/host"
                  "batch"
                ];
                exporters = [ "otlp" ];
              };

              logs = {
                receivers = [ "journald" ];
                processors = [
                  "memory_limiter"
                  "resource/host"
                  "batch"
                ];
                exporters = [ "otlp" ];
              };
            };
          };
        };
      };
    };
}
