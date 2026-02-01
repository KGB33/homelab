{inputs, ...}: {
  flake-file = {
    inputs.comin = {
      url = "github:nlewo/comin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  flake.modules.nixos.comin = {config, ...}: {
    imports = [inputs.comin.nixosModules.comin];

    services.comin = {
      enable = true;
      repositorySubdir = "nixos";
      exporter = {
        openFirewall = false;
        port = 4243;
      };
      remotes = [
        {
          name = "origin";
          url = "https://github.com/KGB33/homelab.git";
          branches.main.name = "main";
        }
      ];
    };

    # TODO: Maybe replace w/ Grafana Mimir
    services.prometheus.scrapeConfigs = [
      {
        job_name = "comin";
        static_configs = [
          {
            targets = ["localhost:${toString config.services.comin.exporter.port}"];
          }
        ];
      }
    ];
  };
}
