{ den, lib, ... }:
let
  inherit (den.lib) diag;
in
{
  perSystem =
    { pkgs, ... }:
    let
      rc = diag.renderContext { inherit pkgs; };
      fleetCapture = diag.captureFleet { };

      stripFrontmatter =
        source:
        let
          lines = lib.splitString "\n" source;
          body = builtins.filter (l: !(lib.hasPrefix "%%{init:" l)) lines;
        in
        lib.concatStringsSep "\n" body;

      scopeTopologySection =
        let
          source = stripFrontmatter (rc.render.toScopeTopologyMermaid fleetCapture);
        in
        ''
          ## Scope Topology

          ```mermaid
          ${source}
          ```
        '';

      namespaceSection =
        let
          namespaceGraph = diag.graph.ofNamespace { };
          source = stripFrontmatter (rc.renderDense.toMermaid namespaceGraph);
        in
        ''
          ## Aspect Namespace

          ```mermaid
          ${source}
          ```
        '';

      fleetSummarySection = ''
        ## Fleet Summary

        ${diag.text.fleetSummary fleetCapture}
      '';

      mkViewFile = name: content: {
        name = "fleet";
        view = name;
        dir = "fleet";
        ext = "md";
        tool = null;
        drv = pkgs.writeText "${name}.md" content;
      };

      everyEntry = [
        (mkViewFile "scope-topology" scopeTopologySection)
        (mkViewFile "namespace" namespaceSection)
        (mkViewFile "summary" fleetSummarySection)
      ];

    in
    {
      packages = diag.export.entriesToPackages everyEntry // {
        write-diagrams = diag.export.mkWriteScript pkgs {
          entries = everyEntry;
          galleries = [ ];
          destExpr = ''"$(${pkgs.git}/bin/git rev-parse --show-toplevel)"'';
        };
      };
    };
}
