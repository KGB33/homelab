{ disk, ... }:
{
  # host aspect
  den.aspects.ophiuchus = {
    includes = [ disk.xfs-impermanence ];
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.hello ];
      };
  };
}
