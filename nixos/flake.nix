{
  description = "NixOS machine configs.";

  inputs = {
    nixpkgs = {url = "github:NixOS/nixpkgs/nixos-unstable-small";};

    impermanence.url = "github:nix-community/impermanence";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    inherit (self) outputs;
    lib = nixpkgs.lib;
  in {
    nixosConfigurations = let
      mkHost = hostname:
        lib.nixosSystem {
          modules = [
            ./hosts/${hostname}/configuration.nix
          ];
          specialArgs = {inherit inputs outputs;};
        };
    in {
      iso = lib.nixosSystem {
        modules = [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-plasma5.nix"
          "${nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
          ./hosts/iso/configuration.nix
        ];
        specialArgs = {inherit inputs outputs;};
      };

      targe = mkHost "targe";
      ophiuchus = mkHost "ophiuchus";
    };
  };
}
