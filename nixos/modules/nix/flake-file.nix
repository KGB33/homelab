{inputs, ...}: {
  imports = [
    inputs.flake-file.flakeModules.dendritic
    inputs.den.flakeModules.dendritic
  ];

  flake-file.formatter = {pkgs, ...}: pkgs.alejandra;
}
