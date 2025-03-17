{config, ...}: {
  services.comin = {
    enable = true;
    flakeSubdirectory = "nixos";
    exporter = {
      openFirewall = false;
      port = 4243;
    };
    remotes = [
      {
        name = "origin";
        url = "https://github.com/KGB33/homelab.git";
        branches.main.name = "main";
        branches.testing.name = "blog-on-nixos";
      }
    ];
  };

  services.prometheus = {
    scrapeConfigs = [
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
