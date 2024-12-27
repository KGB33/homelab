{...}: {
  imports = [
    ../../base/configuration.nix
    ./disks.nix
  ];

  networking = {
    hostName = "ophiuchus";
    hostId = "e7ea22a6"; # `head -c4 /dev/urandom | od -A none -t x4`
  };

  systemd.network = {
    enable = true;
    netdevs."10-vlan9" = {
      netdevConfig = {
        name = "10-vlan9";
        kind = "vlan";
      };
      vlanConfig = {Id = 9;};
    };
    networks."10-enp0s13f0u1" = {
      matchConfig.Name = "enp0s13f0u1";
      gateway = ["10.0.9.1"];
      vlan = ["10-vlan9"];
      networkConfig = {
        Address = "10.0.9.104/24";
      };
    };
  };
}
