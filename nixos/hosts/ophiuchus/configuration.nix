{...}: {
  imports = [../base/configuration.nix ./disks.nix];

  networking = {
    hostName = "ophiuchus";
  };

  systemd.network = {
    enable = true;
    networks."10-ens0" = {
      matchConfig.Name = "ens0";
      networkConfig = {
        Address = "10.0.9.104/24";
      };
    };
  };
}
