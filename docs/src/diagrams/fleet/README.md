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
