{
  flake-file.inputs.dagger.url = "github:dagger/nix";

  perSystem =
    {
      pkgs,
      inputs',
      ...
    }:
    {
      formatter = pkgs.nixfmt-tree;

      devShells.default = pkgs.mkShell {
        buildInputs = [
          inputs'.dagger.packages.dagger
          pkgs.python312Packages.kubernetes

          pkgs.age
          pkgs.argocd
          pkgs.cilium-cli
          pkgs.jq
          pkgs.jsonnet
          pkgs.jsonnet-bundler
          pkgs.just
          pkgs.k9s
          pkgs.kubectl
          pkgs.kubernetes-helm
          pkgs.kubeseal
          pkgs.mdbook
          pkgs.nmap
          pkgs.opentofu
          pkgs.sops
          pkgs.talosctl
          pkgs.yq-go
        ];
      };
    };
}
