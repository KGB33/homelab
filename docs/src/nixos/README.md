# NixOS Server Configs

The `modules/` directory contains the system definitions for all of my NixOS
servers.

## Directory Layout

NixOS is configured using the Dendritic pattern: every file under `modules/` is
auto-imported via `import-tree` and composed with `flake-parts`. Each host has
its own file (e.g. `modules/ophiuchus.nix`, `modules/targe.nix`,
`modules/tower.nix`), shared configuration lives in modules like
`modules/defaults.nix` and `modules/kgb33.nix`.

## Testing 

Automated tests can be run via `nix flake check`.

To spin up an interactive VM for a check, use `nix run .#checks.x86_64-linux.<CHECK_NAME>.driverInteractive`. 

### Running a Host as a VM

Each host can be booted as a local QEMU VM with `nix run .#vm-<HOST_NAME>`.

```bash
nix run .#vm-ophiuchus
nix run .#vm-targe
nix run .#vm-tower
```

Each writes a `<HOST_NAME>.qcow2` disk image in the current directory that
persists state between runs; delete it to start from a clean slate.


### Check Architecture

Checks should be located close to the implementation, in the same file if possible.

Checks for hosts should be in their host file (`modules/<HOST_NAME>.nix`).
Cross-host checks, like the cluster networking test, live in `modules/tests.nix`.





