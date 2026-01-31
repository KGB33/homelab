{
    flake.modules.nixos.ghost = {config, ...}: {
        # TODO: Use diskio?
        fileSystems = {
          "/".device = "/dev/sda";
        };
    };
}
