{...}: {
  imports = [../base/configuration.nix];

  networking = {
    hostName = "targe";
  };

  systemd.network = {
    enable = true;
    networks."10-ens0" = {
      matchConfig.Name = "ens0";
      networkConfig = {
        Address = "10.0.9.120/24";
      };
    };
  };
}
