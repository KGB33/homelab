{
  self,
  inputs,
  ...
}: {
  flake-file.inputs.npwd = {
    url = "github:KGB33/npwd";
  };

  flake.modules.nixos.npwd = {
    config,
    lib,
    ...
  }: {
    imports = with self.modules.nixos; [sops];

    sops.secrets = {
      npwd_surrealdb_env = {
        sopsFile = ../../secrets/npwd/surrealdb.env;
        format = "dotenv";
        restartUnits = ["surrealdb.service"];
      };
      npwd_env = {
        sopsFile = ../../secrets/npwd/npwd.env;
        format = "dotenv";
        restartUnits = ["npwd.service"];
      };
    };

    services.surrealdb = {
      enable = true;
      host = "127.0.0.1";
      port = 8000;
      dbPath = "rocksdb:///var/lib/surrealdb/npwd";
    };

    systemd.services.surrealdb.serviceConfig = {
      EnvironmentFile = config.sops.secrets.npwd_surrealdb_env.path;
      ProcSubset = lib.mkForce "all";
    };

    systemd.services.npwd = {
      description = "NPWD server";
      wantedBy = ["multi-user.target"];
      after = ["network-online.target" "surrealdb.service"];
      wants = ["network-online.target" "surrealdb.service"];

      environment = {
        PORT = "3000";
        SURREAL_HOST = "127.0.0.1";
        SURREAL_PORT = "8000";
        SURREAL_NAMESPACE = "npwd";
        SURREAL_DATABASE = "npwd";
      };

      serviceConfig = {
        ExecStart = "${inputs.npwd.packages.x86_64-linux.npwd}/bin/server";
        EnvironmentFile = config.sops.secrets.npwd_env.path;

        DynamicUser = true;
        Restart = "on-failure";
        RestartSec = "5s";

        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectKernelTunables = true;
        ProtectControlGroups = true;
        RestrictAddressFamilies = ["AF_INET" "AF_INET6" "AF_UNIX"];
        RestrictNamespaces = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = false;
      };
    };
  };

  perSystem = {
    system,
    lib,
    ...
  }: let
    pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfreePredicate = pkg:
        builtins.elem (lib.getName pkg) ["surrealdb"];
    };
  in {
    checks.npwd = pkgs.testers.runNixOSTest {
      name = "npwd";
      nodes.machine = {lib, ...}: {
        imports = with self.modules.nixos; [npwd];

        systemd.services.surrealdb.serviceConfig.EnvironmentFile = lib.mkForce (
          pkgs.writeText "surrealdb-test-env" ''
            SURREAL_USER=root
            SURREAL_PASS=testpass
          ''
        );

        systemd.services.npwd.serviceConfig.EnvironmentFile = lib.mkForce (
          pkgs.writeText "npwd-test-env" ''
            SURREAL_USER=root
            SURREAL_PASSWORD=testpass
            SECRET_KEY_BASE=0000000000000000000000000000000000000000000000000000000000000000
            ADMIN_EMAIL=admin@example.com
            ADMIN_PASSWORD=testadminpass
          ''
        );
      };
      testScript =
        # python
        ''
          machine.wait_for_unit("surrealdb.service")
          machine.wait_until_succeeds("curl -sf http://127.0.0.1:8000/health")
          machine.wait_for_unit("npwd.service")
          machine.wait_until_succeeds("curl -sf http://127.0.0.1:3000/")
        '';
    };
  };
}
