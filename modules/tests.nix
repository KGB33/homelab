{ inputs, den, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      checks.test-cluster = pkgs.testers.runNixOSTest {
        name = "cluster";

        nodes = {
          ophiuchus = den.hosts.x86_64-linux.ophiuchus.mainModule;
          targe = den.hosts.x86_64-linux.targe.mainModule;
          tower = den.hosts.x86_64-linux.tower.mainModule;
        };

        testScript =
          # python
          ''
            ophiuchus.start()
            targe.start()
            tower.start()

            ophiuchus.wait_for_unit("network.target")
            targe.wait_for_unit("network.target")
            tower.wait_for_unit("network.target")

            ophiuchus.succeed("ping -c 3 targe")
            targe.succeed("ping -c 3 ophiuchus")
            tower.succeed("ping -c 3 ophiuchus")
            ophiuchus.succeed("ping -c 3 tower")
          '';
      };
    };
}
