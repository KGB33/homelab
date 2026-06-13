{ inputs, ... }:
{
  disk.xfs-impermanence = {
    nixos = {
      imports = [
        inputs.disko.nixosModules.disko
        inputs.impermanence.nixosModules.impermanence
      ];

      disko.devices = {
        disk.nvme0n1 = {
          type = "disk";
          device = "/dev/nvme0n1";
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                size = "1G";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [ "umask=0077" ];
                };
              };
              nix = {
                size = "100G";
                content = {
                  type = "filesystem";
                  format = "xfs";
                  mountpoint = "/nix";
                };
              };
              persist = {
                size = "100%";
                content = {
                  type = "filesystem";
                  format = "xfs";
                  mountpoint = "/persist";
                };
              };
            };
          };
        };
        nodev."/" = {
          fsType = "tmpfs";
          mountOptions = [
            "defaults"
            "size=2G"
            "mode=755"
          ];
        };
      };

      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      fileSystems."/persist".neededForBoot = true;

      environment.persistence."/persist" = {
        hideMounts = true;
        directories = [
          "/etc/nixos"
          "/etc/ssh"
          "/var/log"
          "/var/lib/nixos"
          "/var/lib/systemd/coredump"
        ];
        files = [
          "/etc/machine-id"
        ];
      };
    };
  };
}
