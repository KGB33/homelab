{self, ...}: {
  flake.modules.nixos.terminus = {
    config,
    lib,
    pkgs,
    ...
  }: {
    imports = with self.modules.nixos; [sops podman];

    networking.firewall.allowedTCPPorts = [7000];

    # --- All Secrets ---
    sops.secrets = {
      terminus_env = {
        sopsFile = ../../secrets/terminus/secrets.env;
        format = "dotenv";
        restartUnits = [
          "podman-terminus-web.service"
          "podman-terminus-worker.service"
        ];
      };
      terminus_db_password = {
        sopsFile = ../../secrets/terminus/dbPassword;
        format = "binary";
        owner = "postgres";
      };
      terminus_keyvalue_password = {
        sopsFile = ../../secrets/terminus/valkeyPassword;
        format = "binary";
        owner = "redis-terminus";
      };
    };

    # --- PostgreSQL ---
    services.postgresql = {
      enable = true;
      ensureDatabases = ["terminus"];
      ensureUsers = [
        {
          name = "terminus";
          ensureDBOwnership = true;
        }
      ];
    };

    # Set password from binary sops file after user is created by postgresql-setup.service
    systemd.services.terminus-db-password-setup = {
      description = "Set terminus database user password";
      after = ["postgresql-setup.service"];
      requires = ["postgresql.service"];
      wantedBy = ["multi-user.target"];
      path = [config.services.postgresql.package];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "postgres";
      };
      script = ''
        psql -tAc "ALTER USER terminus WITH PASSWORD '$(cat ${config.sops.secrets.terminus_db_password.path})';"
      '';
    };

    # --- Valkey (via redis module) ---
    services.redis.package = pkgs.valkey;
    services.redis.servers.terminus = {
      enable = true;
      port = 6379;
      requirePassFile = config.sops.secrets.terminus_keyvalue_password.path;
    };

    # --- Web container ---
    virtualisation.oci-containers.containers.terminus-web = {
      image = "ghcr.io/usetrmnl/terminus:latest";
      autoStart = true;
      ports = ["7000:7000"];
      volumes = ["terminus-uploads:/app/public/uploads"];
      environment = {
        HANAMI_PORT = "7000";
        APP_SETUP = "true";
      };
      environmentFiles = [config.sops.secrets.terminus_env.path];
      extraOptions = [
        "--network=host"
        "--memory=1g"
        "--cpus=1.0"
        "--init"
      ];
    };

    # --- Worker container ---
    virtualisation.oci-containers.containers.terminus-worker = {
      image = "ghcr.io/usetrmnl/terminus:latest";
      autoStart = true;
      cmd = ["bundle" "exec" "sidekiq" "-r" "./config/sidekiq.rb"];
      volumes = ["terminus-uploads:/app/public/uploads"];
      environment = {
        HANAMI_PORT = "7000";
      };
      environmentFiles = [config.sops.secrets.terminus_env.path];
      extraOptions = [
        "--network=host"
        "--memory=1g"
        "--cpus=1.0"
        "--init"
      ];
    };

    # --- Systemd ordering ---
    systemd.services.podman-terminus-web = {
      after = ["postgresql.service" "redis-terminus.service" "terminus-db-password-setup.service"];
      requires = ["postgresql.service" "redis-terminus.service" "terminus-db-password-setup.service"];
    };

    systemd.services.podman-terminus-worker = {
      after = ["podman-terminus-web.service"];
      requires = ["podman-terminus-web.service"];
    };
  };

  perSystem = {
    pkgs,
    lib,
    ...
  }: {
    checks.terminus = pkgs.testers.runNixOSTest {
      name = "terminus";
      nodes.machine = {
        lib,
        pkgs,
        config,
        ...
      }: let
        # Stub image: real image can't be pulled without internet in VM tests
        terminusStub = pkgs.dockerTools.buildLayeredImage {
          name = "ghcr.io/usetrmnl/terminus";
          tag = "latest";
          contents = [pkgs.busybox];
          config.Cmd = [
            "sh"
            "-c"
            "mkdir -p /www && echo ok > /www/up && exec busybox httpd -f -p 7000 -h /www"
          ];
        };
      in {
        imports = with self.modules.nixos; [terminus];

        # Create fake secret files before services start (sops can't decrypt without a key in tests)
        systemd.tmpfiles.rules = [
          "f /run/secrets/terminus_db_password 0440 postgres postgres - testpass"
        ];

        # Override service options directly to bypass sops in tests
        services.redis.servers.terminus.requirePassFile = lib.mkForce (
          toString (pkgs.writeText "test-kv-pass" "testpass")
        );

        # Use stub image instead of pulling from registry
        virtualisation.oci-containers.containers.terminus-web.imageFile = lib.mkForce terminusStub;
        virtualisation.oci-containers.containers.terminus-worker.imageFile = lib.mkForce terminusStub;
        # Worker stub just sleeps (no bundle/sidekiq in stub image)
        virtualisation.oci-containers.containers.terminus-worker.cmd = lib.mkForce ["sh" "-c" "while true; do sleep 60; done"];

        virtualisation.oci-containers.containers.terminus-web.environmentFiles = lib.mkForce [
          (pkgs.writeText "terminus-test-env" ''
            APP_SECRET=test-secret-key
            API_URI=https://api.example.com
            DATABASE_URL=postgres://terminus:testpass@localhost:5432/terminus
            KEYVALUE_URL=redis://:testpass@localhost:6379/0
          '')
        ];

        virtualisation.oci-containers.containers.terminus-worker.environmentFiles = lib.mkForce [
          (pkgs.writeText "terminus-test-env" ''
            APP_SECRET=test-secret-key
            API_URI=https://api.example.com
            DATABASE_URL=postgres://terminus:testpass@localhost:5432/terminus
            KEYVALUE_URL=redis://:testpass@localhost:6379/0
          '')
        ];

        environment.systemPackages = [config.services.redis.package];
      };
      testScript =
        # python
        ''
          machine.wait_for_unit("postgresql.service")
          machine.wait_for_unit("redis-terminus.service")
          machine.wait_for_unit("terminus-db-password-setup.service")
          machine.wait_for_unit("podman-terminus-web.service")
          machine.wait_for_unit("podman-terminus-worker.service")

          # PostgreSQL: verify database and role were actually created
          machine.succeed("su -c \"psql -tAc \\\"SELECT 1 FROM pg_database WHERE datname='terminus'\\\" | grep -q 1\" postgres")
          machine.succeed("su -c \"psql -tAc \\\"SELECT 1 FROM pg_roles WHERE rolname='terminus'\\\" | grep -q 1\" postgres")

          # Valkey: verify authenticated connection works
          machine.succeed("valkey-cli -a testpass ping 2>/dev/null | grep -q PONG")

          # Web: verify HTTP endpoint responds
          machine.wait_until_succeeds("curl -sf http://localhost:7000/up")
        '';
    };
  };
}
