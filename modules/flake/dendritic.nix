{ inputs, ... }:
{

  # flake.den = den; # Uncomment for repl access.

  imports = [
    (inputs.flake-file.flakeModules.dendritic or { })
    (inputs.den.flakeModules.dendritic or { })
  ];

  perSystem =
    { pkgs, ... }:
    {
      formatter = pkgs.nixfmt-tree;
    };

  flake-file.inputs = {
    den.url = "github:denful/den";
    den-diagram.url = "github:denful/den-diagram";
    flake-file.url = "github:vic/flake-file";
  };
}
