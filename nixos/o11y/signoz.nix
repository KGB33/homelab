{ den, o11y, ... }:
let
  ingestDomain = "signoz-ingest.internal.kgb33.dev";
in
{
  o11y.signoz.includes = [ den.aspects.sops ];

  o11y.signoz.nixos =
    { pkgs, config, ... }:
    let
      signoz-pkg = pkgs.stdenvNoCC.mkDerivation rec {
        pname = "signoz";
        version = "v0.137.1";

        nativeBuildInputs = [ pkgs.autoPatchelfHook ];

        src = pkgs.fetchurl {
          url = "https://github.com/SigNoz/signoz/releases/download/${version}/signoz_linux_amd64.tar.gz";
          hash = "sha256-rgN1NKAqEkiaT1KEpDY72w7ogg7umBpYCayNIaxKsbA=";
        };

        dontUnpack = true;
        installPhase = ''
          mkdir -p $out
          tar -xzf $src --strip-components=1 -C $out
        '';
      };

      signoz-otel-collector = pkgs.stdenvNoCC.mkDerivation rec {
        pname = "signoz-otel-collector";
        version = "v0.144.8";

        nativeBuildInputs = [ pkgs.autoPatchelfHook ];

        src = pkgs.fetchurl {
          url = "https://github.com/SigNoz/signoz-otel-collector/releases/download/${version}/signoz-otel-collector_linux_amd64.tar.gz";
          hash = "sha256-ptmlylzoV1rN3eiemylB3iXnluOoCVVX3Ly+zrOoOps=";
        };

        dontUnpack = true;
        installPhase = ''
          mkdir -p $out
          tar -xzf $src --strip-components=1 -C $out
        '';
      };
    in
    {
      networking.firewall.allowedTCPPorts = [ 4317 ];

      users.groups.signoz = { };
      users.users.signoz = {
        isSystemUser = true;
        group = "signoz";
      };

      sops.secrets.cloudflare_acme = {
        sopsFile = ../../secrets/cloudflareSecrets.env;
        format = "dotenv";
      };

      security.acme = {
        acceptTerms = true;
        certs.${ingestDomain} = {
          dnsProvider = "cloudflare";
          environmentFile = config.sops.secrets.cloudflare_acme.path;
          group = "signoz";
          reloadServices = [ "signoz-otel-collector.service" ];
        };
      };

      environment.systemPackages = [
        signoz-pkg
        signoz-otel-collector
      ];

      systemd.services.signoz = {
        enable = true;
        wantedBy = [ "multi-user.target" ];
        after = [
          "postgresql.service"
          "clickhouse.service"
        ];
        requires = [
          "postgresql.service"
          "clickhouse.service"
        ];
        environment = {
          SIGNOZ_WEB_DIRECTORY = "${signoz-pkg}/web";
          SIGNOZ_SQLSTORE_PROVIDER = "postgres";
          SIGNOZ_SQLSTORE_POSTGRES_DSN = "host=/run/postgresql user=signoz dbname=signoz";
        };

        serviceConfig = {
          ExecStart = "${signoz-pkg}/bin/signoz server";
          User = "signoz";
          Group = "signoz";
          StateDirectory = "signoz";
          WorkingDirectory = "/var/lib/signoz";
        };
      };

      systemd.services.signoz-telemetrystore-migrator = {
        enable = true;
        wantedBy = [ "multi-user.target" ];
        before = [ "signoz.service" ];
        after = [ "clickhouse.service" ];
        requires = [ "clickhouse.service" ];
        environment = {
          SIGNOZ_OTEL_COLLECTOR_CLICKHOUSE_DSN = "tcp://localhost:9000";
          SIGNOZ_OTEL_COLLECTOR_TIMEOUT = "10m";
        };
        script = ''
          set -euo pipefail

          collector=${signoz-otel-collector}/bin/signoz-otel-collector

          "$collector" migrate bootstrap
          "$collector" migrate sync up
          "$collector" migrate async up
        '';

        serviceConfig = {
          ExecStartPre = "${signoz-otel-collector}/bin/signoz-otel-collector migrate ready";
          Group = "signoz";
          RemainAfterExit = "yes";
          Restart = "on-failure";
          RestartSec = 5;
          Type = "oneshot";
          User = "signoz";
        };
      };

      systemd.services.signoz-otel-collector = {
        enable = true;
        wantedBy = [ "multi-user.target" ];
        after = [ "acme-${ingestDomain}.service" ];
        requires = [ "acme-${ingestDomain}.service" ];
        environment = {
          SIGNOZ_OTEL_COLLECTOR_CLICKHOUSE_DSN = "tcp://localhost:9000";
          SIGNOZ_OTEL_COLLECTOR_TIMEOUT = "10m";
        };
        script = "${signoz-otel-collector}/bin/signoz-otel-collector --config=${./signoz/otel-collector.yaml}";
        serviceConfig = {
          ExecStartPre = [
            "${signoz-otel-collector}/bin/signoz-otel-collector migrate sync check"
          ];
          Group = "signoz";
          KillMode = "mixed";
          Restart = "on-failure";
          RestartSec = 5;
          Type = "simple";
          User = "signoz";
        };
      };

      services.postgresql = {
        enable = true;
        package = pkgs.postgresql_19;
        ensureDatabases = [ "signoz" ];
        ensureUsers = [
          {
            name = "signoz";
            ensureDBOwnership = true;
          }
        ];
      };

      services.clickhouse = {
        enable = true;
        serverConfig = {
          listen_host = "127.0.0.1";
          interserver_http_port = 9010;

          display_name = "cluster";

          distributed_ddl.path = "/clickhouse/task_queue/ddl";

          macros = {
            shard = "00";
            replica = "00";
          };

          remote_servers.cluster.shard = [
            {
              replica = [
                {
                  host = "127.0.0.1";
                  port = 9000;
                }
              ];
            }
          ];

          zookeeper.node = [
            {
              host = "127.0.0.1";
              port = config.services.zookeeper.port;
            }
          ];

          logger = {
            console = 1;
            level = "information";
          };
        };
        usersConfig = {
          profiles.default = {
            allow_simdjson = 0;
            load_balancing = "random";
            log_queries = 1;
          };

          users.default = {
            show_named_collection = 1;
            show_named_collection_secrets = 1;
          };
        };
      };

      services.zookeeper = {
        enable = true;
        extraConf = ''
          admin.serverAddress=127.0.0.1
          admin.serverPort=8081
          clientPortAddress=127.0.0.1
          initLimit=5
          syncLimit=2
          tickTime=2000
        '';

      };
    };

  den.hosts.x86_64-linux.check-signoz = {
    intoAttr = [ ];
    aspect = o11y.signoz;
  };

  perSystem =
    { pkgs, ... }:
    {
      checks.signoz = pkgs.testers.runNixOSTest {
        name = "Signoz Check";
        nodes = {
          machine = {
            imports = [
              den.hosts.x86_64-linux.check-signoz.mainModule
            ];
            networking.hostName = "signoz";
          };
        };

        interactive.nodes.machine = {
          networking.firewall.allowedTCPPorts = [ 8080 ];

          virtualisation.forwardPorts = [
            {
              from = "host";
              host.address = "127.0.0.1";
              host.port = 18080;
              guest.port = 8080;
            }
          ];
        };

        testScript =
          # python
          ''
            machine.wait_for_unit("postgresql.service")
            machine.wait_for_unit("postgresql-setup.service")
            machine.wait_for_unit("zookeeper.service")
            machine.wait_for_unit("clickhouse.service")
            machine.wait_for_unit("signoz-telemetrystore-migrator.service")
            machine.wait_for_unit("signoz-otel-collector.service")
            machine.wait_for_unit("signoz.service")
            machine.wait_until_succeeds(
              "curl -fsS http://127.0.0.1:8080/api/v1/health"
            )
          '';
      };

    };
}
