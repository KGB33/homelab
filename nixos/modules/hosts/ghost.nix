{
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "ghost";

  perSystem = {pkgs, ...}: {
    checks.ghost = pkgs.testers.runNixOSTest {
      name = "Ghost Host Test";
      nodes.ghost = {...}: {
        imports = with self.modules.nixos; [ghost];
      };
      testScript =
        # python
        ''
          ghost.start()
        '';
    };
  };
}
