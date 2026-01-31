# NixOS Server Configs

The `nixos/` directory contains the system definitions for all of my NixOS
servers.

To reload the config, see [here](/nixos/GitOps.html#rebuilding).

## Directory Layout

NixOS is configured using the Dendritic pattern.

## Testing 

Automated tests can be ran via `nix flake check`.

To spin up an interactive VM for a check, use `nix run .#checks.x86_64-linux.<CHECK_NAME>.driverInteractive`. 


### Check Architecture

Checks should be located close to the implementation, in the same file if possible.

Checks for hosts should be in their host file (`modules/hosts/<HOST_NAME>.nix`).





