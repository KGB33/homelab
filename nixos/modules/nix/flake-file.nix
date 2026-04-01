{inputs, ...}: {
  imports = [
    inputs.flake-file.flakeModules.dendritic
  ];

  flake-file.formatter = {pkgs, ...}: pkgs.alejandra;
}
