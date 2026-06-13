# enables `nix run .#vm-<host>`. it is very useful to have a VM
{
  inputs,
  den,
  lib,
  ...
}:
{
  den.aspects = lib.mapAttrs (_: _: {
    includes = [ (den.batteries.tty-autologin "kgb33") ];
  }) den.hosts.x86_64-linux;

  perSystem =
    { pkgs, ... }:
    let
      mkVm =
        name:
        let
          host = inputs.self.nixosConfigurations.${name}.config;
        in
        pkgs.writeShellApplication {
          name = "vm-${host.networking.hostName}";
          text = ''
            ${host.system.build.vm}/bin/run-${host.networking.hostName}-vm "$@"
          '';
        };
    in
    {
      packages = lib.mapAttrs' (
        name: _: lib.nameValuePair "vm-${name}" (mkVm name)
      ) den.hosts.x86_64-linux;
    };
}
