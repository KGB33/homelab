# enables `nix run .#vm-<host>`. it is very useful to have a VM
{ inputs, den, ... }:
{
  den.aspects.ophiuchus.includes = [ (den.batteries.tty-autologin "kgb33") ];
  den.aspects.targe.includes = [ (den.batteries.tty-autologin "kgb33") ];
  den.aspects.tower.includes = [ (den.batteries.tty-autologin "kgb33") ];

  perSystem =
    { pkgs, ... }:
    let
      mkVm =
        host:
        pkgs.writeShellApplication {
          name = "vm-${host.networking.hostName}";
          text = ''
            ${host.system.build.vm}/bin/run-${host.networking.hostName}-vm "$@"
          '';
        };
    in
    {
      packages.vm-ophiuchus = mkVm inputs.self.nixosConfigurations.ophiuchus.config;
      packages.vm-targe = mkVm inputs.self.nixosConfigurations.targe.config;
      packages.vm-tower = mkVm inputs.self.nixosConfigurations.tower.config;
    };
}
