{ disk, ... }:
{
  den.default = {
    nixos.system.stateVersion = "25.11";
    includes = [ disk.xfs-impermanence ];
  };
}
