{inputs, ...}: {
  flake-file.inputs.sops-nix = {
    url = "github:Mic92/sops-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake.modules.nixos.sops = {...}: {
    imports = [inputs.sops-nix.nixosModules.sops];

    sops = {
      defaultSopsFormat = "yaml";
      age.keyFile = "/todo";
    };
  };
}
