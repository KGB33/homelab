{...}: {
  imports = [
    ./comin.nix
    ./openssh.nix
    ./sops.nix
  ];

  virtualisation.docker = {
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };
  virtualisation.oci-containers.backend = "docker";
}
