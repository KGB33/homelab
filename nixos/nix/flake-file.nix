{ inputs, ... }: {
  imports = [
    inputs.flake-file.flakeModules.dendritic
    inputs.den.flakeModules.dendritic
  ];

  flake-file.formatter = { pkgs, ... }: pkgs.nixfmt;

  flake-file.outputs = ''
    inputs: inputs.flake-parts.lib.mkFlake {inherit inputs;} (inputs.import-tree ./nixos)
  '';
}
