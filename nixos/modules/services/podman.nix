{...}: {
  den.aspects.podman.nixos = {
    virtualisation = {
      containers.enable = true;
      oci-containers.backend = "podman";
      podman = {
        enable = true;
        dockerCompat = true;
        dockerSocket.enable = true;
      };
    };
  };
}
