{ ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      mdbook-packages = [
        pkgs.mdbook
        pkgs.mdbook-mermaid
      ];
    in
    {
      devShells.default = pkgs.mkShell {
        packages = mdbook-packages;
      };

      packages.docs = pkgs.stdenv.mkDerivation {
        name = "docs";
        src = ../docs;
        nativeBuildInputs = mdbook-packages;
        buildPhase = ''
          mdbook-mermaid install .
          mdbook build
        '';
        installPhase = "mv book $out";
      };
    };
}
