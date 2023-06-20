{
  description = "Homelab toolbox";

  inputs = {
    nixpkgs = { url = "github:NixOS/nixpkgs/nixos-unstable-small"; };
    flake-utils = { url = "github:numtide/flake-utils"; };
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        pyPkgs = pkgs.python311Packages;

      in
      {
        # enable `nix fmt`
        formatter = pkgs.nixpkgs-fmt;

        devShell = pkgs.mkShell {
          buildInputs = [
            pyPkgs.paramiko
            pyPkgs.ansible-core
            pyPkgs.ansible
            pyPkgs.requests
            #pkgs.ansible-lint # Breaks cffi in paramiko
            pkgs.terraform
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
          ];
        };

      });
}
