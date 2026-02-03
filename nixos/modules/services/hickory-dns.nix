{self, ...}: {
  flake.modules.nixos.hickory-dns = {...}: {
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
            zone = ".";
            zone_type = "External";
            stores = {
              type = "forward";
              name_servers = [
                {
                  socket_addr = "8.8.8.8:53";
                  protocol = "udp";
                  trust_negative_responses = false;
                }
                {
                  socket_addr = "8.8.8.8:53";
                  protocol = "tcp";
                  trust_negative_responses = false;
                }
              ];
            };
          }
        ];
      };
    };
  };

  perSystem = {pkgs, ...}: {
    checks.hickory-dns = pkgs.testers.runNixOSTest {
      name = "Basic hickory-dns check";
      nodes.machine = {...}: {
        imports = with self.modules.nixos; [hickory-dns];
        environment.systemPackages = [ pkgs.doggo ];
      };
      testScript =
        # python
        ''
          machine.wait_for_unit("hickory-dns.service")
          doggo = machine.succeed("doggo -J nixos-test.internal.kgb33.dev TXT @localhost")
          assert "A test record for assertions in runNixOSTest" in doggo
        '';
    };
  };
}
