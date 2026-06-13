{ den, lib, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      hosts = den.hosts.x86_64-linux;
      names = builtins.attrNames hosts;
      boot = lib.concatMapStringsSep "\n" (name: ''
        ${name}.start()
        ${name}.wait_for_unit("network.target")
      '') names;
      ping = lib.concatMapStringsSep "\n" (
        from:
        lib.concatMapStringsSep "\n" (to: ''${from}.succeed("ping -c 3 ${to}")'') (
          lib.filter (to: to != from) names
        )
      ) names;
    in
    {
      checks.test-cluster = pkgs.testers.runNixOSTest {
        name = "cluster";

        nodes = lib.mapAttrs (_: host: host.mainModule) hosts;

        testScript =
          # python
          ''
            ${boot}

            ${ping}
          '';
      };
    };
}
