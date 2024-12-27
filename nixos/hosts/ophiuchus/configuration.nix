{inputs, ...}: {
  imports = [
    ../base/configuration.nix
    inputs.disko.nixosModules.disko
    ./disks.nix
  ];
  diskio.devices.disk.main.device = "/dev/nvme0n1";

  networking = {
    hostName = "ophiuchus";
    hostId = "e7ea22a6"; # `head -c4 /dev/urandom | od -A none -t x4`
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
