{...}: {
  imports = [
    ./comin.nix
    ./monitoring.nix
    ./openssh.nix
    ./sops.nix
  ];

  virtualisation.docker.enable = true;
  virtualisation.oci-containers.backend = "docker";
}
