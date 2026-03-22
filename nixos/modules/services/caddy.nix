{self, ...}: {
  flake.modules.nixos.caddy = {config, pkgs, ...}: {
    imports = with self.modules.nixos; [sops podman];

    networking.firewall.allowedTCPPorts = [443];

    sops.secrets."cloudflare_dns" = {
      sopsFile = ../../secrets/cloudflareSecrets.env;
      format = "dotenv";
      restartUnits = ["caddy.service"];
    };

    virtualisation.oci-containers.containers.blog = {
      image = "ghcr.io/kgb33/blog.kgb33.dev:latest";
      pull = "newer";
      ports = ["1313:1313"];
    };

    services.caddy = {
      enable = true;
      package = pkgs.caddy.withPlugins {
        plugins = ["github.com/caddy-dns/cloudflare@v0.2.1"];
        hash = "sha256-AcWko5513hO8I0lvbCLqVbM1eWegAhoM0J0qXoWL/vI=";
      };
      environmentFile = config.sops.secrets.cloudflare_dns.path;
      globalConfig = ''
        admin

        metrics
      '';
      virtualHosts = let
        reverseProxy = port: ''
          reverse_proxy localhost:${toString port}

          tls {
            dns cloudflare {
              api_token {env.CF_API_TOKEN}
            }
          }
        '';
      in {
        "blog.kgb33.dev".extraConfig = reverseProxy 1313;
        "${config.services.grafana.settings.server.domain}".extraConfig =
          reverseProxy config.services.grafana.settings.server.http_port;
        "${config.virtualisation.oci-containers.containers.mealie.environment.BASE_URL}".extraConfig =
          reverseProxy 9925;
      };
    };

    services.prometheus.scrapeConfigs = [
      {
        job_name = "caddy";
        static_configs = [{targets = ["localhost:2019"];}];
      }
    ];
  };
}
