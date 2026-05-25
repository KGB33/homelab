# enables `nix run .#vm-ophiuchus`. it is very useful to have a VM
{ inputs, den, ... }:
{
  den.aspects.ophiuchus.includes = [ (den.batteries.tty-autologin "kgb33") ];

  perSystem =
    { pkgs, ... }:
    {
      packages.vm-ophiuchus = pkgs.writeShellApplication {
        name = "vm-ophiuchus";
        text =
          let
            host = inputs.self.nixosConfigurations.ophiuchus.config;
          in
          ''
            ${host.system.build.vm}/bin/run-${host.networking.hostName}-vm "$@"
          '';
      };
    };
}
