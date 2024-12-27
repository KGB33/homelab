{config, ...}: {
  imports = [../base/configuration.nix];

  networking = {
    wireless.iwd.enable = true;
    hostName = "iso";
  };

  systemd.network = {
    enable = true;
    networks."10-wlan0" = {
      matchConfig.Name = "wlan0";
      networkConfig.DHCP = "yes";
    };
    networks."05-ens0" = {
      matchConfig.Name = "ens0";
      networkConfig.DHCP = "yes";
    };
  };
}
