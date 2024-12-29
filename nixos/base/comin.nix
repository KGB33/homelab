{...}: {
  services.comin = {
    enable = true;
    flakeSubdirectory = "nixos";
    remotes = [
      {
        name = "orgin";
        url = "https://github.com/KGB33/homelab.git";
      }
    ];
  };
}
