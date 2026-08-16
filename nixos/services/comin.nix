{ inputs, ... }: {
  flake-file = {
    inputs.comin = {
      url = "github:nlewo/comin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  den.aspects.comin.nixos = {
    imports = [ inputs.comin.nixosModules.comin ];

    services.comin = {
      enable = true;
      exporter = {
        openFirewall = false;
        port = 4243;
      };
      remotes = [
        {
          name = "origin";
          url = "https://github.com/KGB33/homelab.git";
          branches.main.name = "main";
        }
      ];
    };
  };
}
