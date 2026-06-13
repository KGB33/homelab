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

      fleetSummarySection = diagram.text.fleetSummary fleetCapture;

      readmeSection = ''
        # Fleet Diagrams

        These diagrams are generated from the [den](https://github.com/denful/den)
        fleet capture by `modules/diagrams.nix`, so they always reflect the current
        set of hosts, users, and aspects.

        ## Generating

        To regenerate the diagrams into `docs/src/diagrams/fleet/`, run:

        ```bash
        nix run .#write-diagrams
        ```

        > Do not edit any file in `docs/src/diagrams/` by hand — `write-diagrams`
        > deletes and recreates the whole directory, including this README.
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
        (mkViewFile "README" readmeSection)
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
