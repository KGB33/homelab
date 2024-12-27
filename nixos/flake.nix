{
  description = "NixOS machine configs.";

  inputs = {
    nixpkgs = {url = "github:NixOS/nixpkgs/nixos-unstable-small";};
    flake-utils = {url = "github:numtide/flake-utils";};
  };

  outputs = {
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      lib = pkgs.lib;
    in {
      targeIso = lib.nixosSystem {
        modules = [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/iso-image.nix"
          "${nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
          ./hosts/base/configuration.nix
        ];
      };
      targe = lib.nixosSystem {
        modules = [
          ./host/targe/configuration.nix
        ];
      };
    });
}
