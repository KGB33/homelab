{inputs, ...}: {
  flake-file.inputs.sops-nix = {
    url = "github:Mic92/sops-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake.modules.nixos.sops = {...}: {
    imports = [inputs.sops-nix.nixosModules.sops];

    sops = {
      defaultSopsFile = ../../secrets/default.yaml;
      defaultSopsFormat = "yaml";
      age.keyFile = "/home/kgb33/.config/sops/age/keys.txt";
    };
  };
}
