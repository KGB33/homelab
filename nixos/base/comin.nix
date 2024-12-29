{...}: {
  services.comin = {
    enable = true;
    flakeSubdirectory = "nixos";
    remotes = [
      {
        name = "origin";
        url = "https://github.com/KGB33/homelab.git";
        branches.main.name = "main";
        branches.testing.name = "nixos-is-the-new-proxmox";
      }
    ];
  };
}
