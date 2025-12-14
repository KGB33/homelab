{
  config,
  pkgs,
  ...
}: {
  sops = {
    defaultSopsFile = ./wireguard/keys.yaml;

    secrets = let
      permissions = {
        owner = "systemd-network";
        group = "systemd-network";
        mode = "0400";
      };
    in {
      server-private-key = permissions;
      geppetto-psk = permissions;
      px10fold-psk = permissions;
    };
  };

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  networking = let
    externalIf = "vlan9";
  in {
    nat = {
      enable = true;
      externalInterface = externalIf;
      internalInterfaces = ["wg0"];
    };

    firewall = {
      enable = true;
      allowedUDPPorts = [51823];
      extraCommands = ''
        iptables -A FORWARD -i wg0 -j ACCEPT
        iptables -A FORWARD -o wg0 -j ACCEPT
        iptables -t nat -A POSTROUTING -s 10.0.4.0/24 -o ${externalIf} -j MASQUERADE
      '';
    };

    wireguard.interfaces = {
      wg0 = {
        ips = ["10.0.4.1/24"];
        listenPort = 51823;
        privateKeyFile = config.sops.secrets.server-private-key.path;
        peers = [
          # `geppetto` - Framework 16
          {
            publicKey = "5wpRiibXX/ODO0qKaZM2lDr07l5RBi/HKup2RGhR6RU=";
            presharedKeyFile = config.sops.secrets.geppetto-psk.path;
            allowedIPs = ["10.0.4.2/32"];
          }

          # Pixel 10 Fold
          {
            publicKey = "FuhQ5OsHnLzFjFkLFkuYxz9dSvmtLycHI5oNbIjBBVk=";
            presharedKeyFile = config.sops.secrets.px10fold-psk.path;
            allowedIPs = ["10.0.4.3/32"];
          }
        ];
      };
    };
  };
}
