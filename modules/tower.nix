{ disk, ... }:
{
  den.aspects.tower = {
    includes = [ disk.xfs-impermanence ];
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.hello ];
      };
  };
}
