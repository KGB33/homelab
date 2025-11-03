{
  config,
  pkgs,
  ...
}: {
  networking.firewall = {
    allowedUDPPorts = [53];
    allowedTCPPorts = [853];
  };

  services.blocky = {
    enable = true;
    settings = {
      upstreams = {
        init.strategy = "fast";
        groups = {
          default = [
            "https://cloudflare-dns.com/dns-query"
            "1.1.1.1"
            "1.0.0.1"
          ];
        };
      };
      customDNS = {
        customTTL = "30s";
        mapping = {
          "mealie.kgb33.dev" = "10.0.9.104";
        };
      };
      blocking = {
        denylists = {
          adds = [
            "https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt"
            "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
            "http://sysctl.org/cameleon/hosts"
            "https://s3.amazonaws.com/lists.disconnect.me/simple_tracking.txt"
          ];
          social = [
            "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/social-only/hosts"
          ];
        };
        clientGroupsBlock = let
          # hannahLaptop = "10.0.7.19";
          hannahPhone = "10.0.7.24";
          blockForHannah = ["adds" "social"];
        in {
          default = ["adds"];
          # ${hannahLaptop} = blockForHannah;
          ${hannahPhone} = blockForHannah;
        };
      };
      prometheus.enable = true;
      ports = let
        baseIp = "10.0.9.53";
      in {
        dns = "${baseIp}:53";
        tls = "${baseIp}:853";
        http = "4000";
      };
    };
  };

  systemd = {
    timers = let
      blockyTimer = switch: time: {
        description = "${switch} Blocky social media group";
        wantedBy = ["timers.target"];
        timerConfig = {
          OnCalendar = time;
          Persistent = true;
          Unit = "blocky-social-${switch}.service";
        };
      };
    in {
      blocky-social-disable = blockyTimer "disable" "08:00:00";
      blocky-social-enable = blockyTimer "enable" "20:00:00";
    };

    services = {
      blocky-social-disable = {
        description = "Manage Blocky Social (Disable)";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = ["${pkgs.blocky}/bin/blocky blocking disable --groups social"];
        };
      };
      blocky-social-enable = {
        description = "Manage Blocky (Enable All)";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = ["${pkgs.blocky}/bin/blocky blocking enable"];
        };
      };
    };
  };

  services.prometheus = {
    enable = true;
    scrapeConfigs = [
      {
        job_name = "blocky";
        static_configs = [
          {
            targets = [
              "localhost:${config.services.blocky.settings.ports.http}"
            ];
          }
        ];
      }
    ];
  };
}
