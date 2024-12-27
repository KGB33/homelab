{...}: {
  imports = [../base/disks.nix];
  disko.devices.disk.main.device = "/dev/nvme0n1";
}
