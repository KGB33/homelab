{
  perSystem = { pkgs, ... }: {
    packages.mdbook_docs = pkgs.stdenv.mkDerivation {
      pname = "docs";
      version = "0.1.0";
      src = ../../docs;
      buildInputs = with pkgs; [ mdbook ];
      buildPhase = ''
        mdbook build .
        mv book $out
      '';
    };
  };
}
