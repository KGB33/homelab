{
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations = inputs.self.lib.mkNixos "x86_64-linux" "ghost";
  flake.checks."x86_64-linux".ghostNixos = inputs.nixpkgs.legacyPackages.x86_64-linux.testers.runNixOSTest {
    name = "Hello Ghost";
    nodes = {
      ghost = {pkgs, ...}: {
        imports = [self.modules.nixos.ghost];
      };
    };
    testScript = ''
      start_all()
      # wait for our service to start
      ghost.wait_for_unit("hello-world-server")
      ghost.wait_for_open_port(8000)
      output = ghost.succeed("curl localhost:8000/indrx.html")
      # Check if our webserver returns the expected result
      assert "Hello world" in output, f"'{output}' does not contain 'Hello world'"
    '';
  };
}
