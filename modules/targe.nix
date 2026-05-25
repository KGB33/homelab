{ disk, ... }:
{
  den.aspects.targe = {
    includes = [ disk.xfs-impermanence ];
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.hello ];
      };
  };
}
