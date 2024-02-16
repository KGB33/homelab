{
  description = "Homelab toolbox";

  inputs = {
    nixpkgs = { url = "github:NixOS/nixpkgs/nixos-unstable"; };
    flake-utils = { url = "github:numtide/flake-utils"; };
    dagger = {
      url = "github:dagger/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, dagger }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        # enable `nix fmt`
        formatter = pkgs.nixpkgs-fmt;

        devShell = pkgs.mkShell {
          buildInputs = [
            # tqdm does not work on Py-3.12
            # https://github.com/tqdm/tqdm/issues/1537
            # pkgs.python312Packages.ansible-core
            # pkgs.python312Packages.ansible
            # pkgs.python312Packages.kubernetes
            # pkgs.ansible-lint

            pkgs.python312
            pkgs.black
            pkgs.opentofu
            pkgs.ansible-language-server
            pkgs.talosctl
            pkgs.kubectl
            pkgs.kubeseal
            pkgs.cilium-cli
            pkgs.jq
            pkgs.yq-go
            pkgs.argocd
            pkgs.jsonnet
            pkgs.jsonnet-bundler
            pkgs.just
            dagger.packages.${system}.dagger
          ];
        };

      });
}
