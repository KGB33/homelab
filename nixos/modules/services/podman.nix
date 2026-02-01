{...}: {
  flake.modules.nixos.podman = {...}: {
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
