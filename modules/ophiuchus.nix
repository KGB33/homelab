{
  # host aspect
  den.aspects.ophiuchus = {
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.hello ];
      };
  };
}
