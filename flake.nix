{
  description = "Homelab toolbox";

  inputs = {
    nixpkgs = { url = "github:NixOS/nixpkgs/nixos-unstable-small"; };
    dagger = { url = "github:dagger/nix"; };
    flake-utils = { url = "github:numtide/flake-utils"; };
  };

  outputs = { self, nixpkgs, flake-utils, dagger }:
    flake-utils.lib.eachDefaultSystem (system:
      let
	dag = dagger.packages.${system};
        pkgs = nixpkgs.legacyPackages.${system};
        pyPkgs = pkgs.python311Packages;
      in
      {
        # enable `nix fmt`
        formatter = pkgs.nixpkgs-fmt;

        devShell = pkgs.mkShell {
          buildInputs = [
	    dag.dagger
            pyPkgs.ansible-core
            pyPkgs.ansible
            pyPkgs.kubernetes
            pkgs.ansible-language-server
            pkgs.ansible-lint
            pkgs.argocd
            pkgs.kubernetes-helm
            pkgs.cilium-cli
            pkgs.jq
            pkgs.jsonnet
            pkgs.jsonnet-bundler
            pkgs.just
            pkgs.k9s
            pkgs.kubectl
            pkgs.kubeseal
            pkgs.mdbook
            pkgs.opentofu
            pkgs.talosctl
            pkgs.yq-go
          ];
        };

      });
}
