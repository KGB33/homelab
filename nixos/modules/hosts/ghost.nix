{den, ...}: {
  den.hosts.x86_64-linux.ghost.users.kgb33 = {};

  perSystem = {pkgs, ...}: {
    checks.ghost = pkgs.testers.runNixOSTest {
      name = "Ghost Host Test";
      nodes.ghost = den.hosts.x86_64-linux.ghost.mainModule;
      testScript =
        # python
        ''
          ghost.start()
        '';
    };
  };
}
