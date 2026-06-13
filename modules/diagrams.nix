{ den, lib, inputs, ... }:
let
  diagram = inputs.den-diagram.lib;
in
{
  perSystem =
    { pkgs, ... }:
    let
      rc = diagram.renderContext { inherit pkgs; };
      fleetCapture = den.lib.capture.captureFleet { };

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
          namespaceGraph = diagram.graph.ofNamespace {
            aspects = den.aspects or { };
            filter = v: v.name != "wsl-host-aspect";
          };
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

        ${diagram.text.fleetSummary fleetCapture}
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
      packages = diagram.export.entriesToPackages everyEntry // {
        write-diagrams = diagram.export.mkWriteScript pkgs {
          entries = everyEntry;
          galleries = [ ];
          destExpr = ''"$(${pkgs.git}/bin/git rev-parse --show-toplevel)/docs/src"'';
        };
      };
    };
}
