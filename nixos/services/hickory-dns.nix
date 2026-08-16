{ den, ... }: {
  den.aspects.hickory-dns.nixos = {
    networking.firewall.allowedTCPPorts = [ 53 ];
    networking.firewall.allowedUDPPorts = [ 53 ];

    services.resolved.settings.Resolve.DNSStubListener = "no";

    services.hickory-dns = {
      enable = true;
      settings = {
        zones = [
          {
            zone = "internal.kgb33.dev.";
            zone_type = "Primary";
            file = ./hickory-dns/internal.zone;
          }
          {
            zone = "kgb33.dev.";
            zone_type = "Primary";
            file = ./hickory-dns/kgb33.dev.zone;
          }
          {
            zone = ".";
            zone_type = "External";
            stores = {
              type = "forward";
              name_servers = [
                {
                  ip = "8.8.8.8";
                  trust_negative_responses = false;
                  connections = [
                    {
                      port = 53;
                      protocol.type = "udp";
                    }
                    {
                      port = 53;
                      protocol.type = "tcp";
                    }
                  ];
                }
              ];
            };
          }
        ];
      };
    };
  };

  den.hosts.x86_64-linux.check-hickory-dns = {
    intoAttr = [ ];
    aspect = den.aspects.hickory-dns;
  };

  perSystem = { pkgs, ... }: {
    checks.hickory-dns = pkgs.testers.runNixOSTest {
      name = "Basic hickory-dns check";
      nodes.machine = {
        imports = [ den.hosts.x86_64-linux.check-hickory-dns.mainModule ];
        environment.systemPackages = [ pkgs.doggo ];
      };
      testScript =
        # python
        ''
          machine.wait_for_unit("hickory-dns.service")

          signoz_ingest = machine.succeed(
              "doggo -J signoz-ingest.internal.kgb33.dev A @localhost"
          )
          assert "10.0.9.104" in signoz_ingest

          signoz_ui = machine.succeed("doggo -J signoz.kgb33.dev A @localhost")
          assert "10.0.9.100" in signoz_ui
        '';
    };
  };
}
