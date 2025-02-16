{...}: {
  imports = [
    ./comin.nix
    ./monitoring.nix
    ./openssh.nix
    ./sops.nix
  ];

  virtualisation.oci-containers.backend = "podman";
}
