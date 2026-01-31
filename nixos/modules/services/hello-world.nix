{self, ...}: {
  flake.modules.nixos.hello-world-server = {
    pkgs,
    lib,
    ...
  }: let
    hello-world-server = pkgs.runCommand "hello-world-server" {} ''
      mkdir -p $out/{bin,/share/webroot}
      cat > $out/share/webroot/index.html <<EOF
      <html><head><title>Hello world</title></head><body><h1>Hello World!</h1></body></html>
      EOF
      cat > $out/bin/hello-world-server <<EOF
      #!${pkgs.runtimeShell}
      exec ${lib.getExe pkgs.python3} -m http.server 8000 --dir "$out/share/webroot"
      EOF
      chmod +x $out/bin/hello-world-server
    '';
  in {
    systemd.services.hello-world-server = {
      after = ["network.target"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        DynamicUser = true;
        ExecStart = lib.getExe' hello-world-server "hello-world-server";
      };
    };
  };

  perSystem = {pkgs, ...}: {
    checks.hello-world-server = pkgs.testers.runNixOSTest {
      name = "Check Hello World Server Index";
      nodes.machine = {...}: {
        imports = with self.modules.nixos; [hello-world-server];
      };
      testScript =
        # python
        ''
          machine.wait_for_unit("hello-world-server")
          machine.wait_for_open_port(8000)
          output = machine.succeed("curl localhost:8000/index.html")
          # Check if our webserver returns the expected result
          assert "Hello world" in output, f"'{output}' does not contain 'Hello world'"
        '';
    };
  };
}
