{config, ...}: let
  hostName = "targe";
in {
  imports = [
    ../../base/configuration.nix
    ./disks.nix
  ];

  networking = {
    hostName = hostName;
    hostId = config.shared.hosts.${hostName}.hostId;
    firewall = {
      allowedUDPPorts = [53];
      allowedTCPPorts = [853];
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
      "10-enp" = {
        matchConfig.Name = "enp7s0f1";
        vlan = ["vlan9"];
        networkConfig.LinkLocalAddressing = "no";
        linkConfig.RequiredForOnline = "carrier";
      };

      "10-vlan9" = {
        matchConfig.Name = "vlan9";
        gateway = ["10.0.9.1"];
        addresses = [
          {
            Address = with config.shared.hosts.${hostName}; "${ipv4}/${ipv4Mask}";
          }
          {
            Address = "10.0.9.53/24";
          }
        ];
      };
    };
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
      blocking = {
        denylists = {
          adds = [
            "https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt"
            "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
            "http://sysctl.org/cameleon/hosts"
            "https://s3.amazonaws.com/lists.disconnect.me/simple_tracking.txt"
          ];
          hannah = [];
        };
        clientGroupsBlock = let
          hannahLaptop = "10.0.7.19";
          hannahPhone = "10.0.7.24";
          blockForHannah = ["adds" "hannah"];
        in {
          default = ["adds"];
          ${hannahLaptop} = blockForHannah;
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
          Unit = "blocky-ads@${switch}.service";
        };
      };
    in {
      "blocky-ads@disable" = blockyTimer "disable" "20:00:00";
      "blocky-ads@enable" = blockyTimer "enable" "10:00:00";
    };

    services."blocky-ads" = {
      description = "Manage Blocky Ads (%i)";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = ["/usr/bin/blocky blocking %i --groups ads"];
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
