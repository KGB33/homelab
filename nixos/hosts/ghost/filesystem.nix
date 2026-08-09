{ ... }: {
  # TODO: Use diskio?
  den.aspects.ghost.nixos.fileSystems = {
    "/" = {
      device = "/dev/sda";
      fsType = "ext4";
    };
  };
}
