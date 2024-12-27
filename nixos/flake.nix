{
  description = "NixOS machine configs.";

  inputs = {
    nixpkgs = {url = "github:NixOS/nixpkgs/nixos-unstable-small";};
    systems.url = "github:nix-systems/default-linux";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
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
            ./host/${hostname}/configuration.nix
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
