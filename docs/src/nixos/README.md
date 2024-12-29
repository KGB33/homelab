# NixOS Server Configs

The `nixos/` directory contains the system definitions for all of my NixOS
servers.

This will (or maybe has already) replace Proxmox. However, Talos' configuration
is already declarative, eventually I'll build out a Nix (or some other fancy
config language - `CUE`? `Dhall`? `pkl`? `Nickel`?) module to generate the config.


## Directory Layout

```
nixos/
├── base
│   ├── configuration.nix
│   └── users.nix
├── flake.nix
├── hosts
│   ├── iso
│   │   ├── cloneRepo.fish
│   │   ├── configuration.nix
│   │   └── installScript.sh
│   ├── ophiuchus
│   │   ├── configuration.nix
│   │   └── disks.nix
│   ├── ...
│   └── targe
│       ├── configuration.nix
│       └── disks.nix
└── justfile

```

The largest part is the machine configuration. 

`base` contains configuration common to all machines, stuff like my user,
enabling flakes, and setting networking DNS servers and domain names.

`hosts/<HOSTNAME>/` contains machine specific configurations.

The `hosts/iso/` is designed to be booted via a USB stick to easily install the other systems.

Next `flake.nix` grabs each host and provides a way to build them.

```
$ nix flake show
git+file:///home/kgb33/Code/homelab?dir=nixos
└───nixosConfigurations
    ├───iso: NixOS configuration
    ├───ophiuchus: NixOS configuration
    ├───...
    └───targe: NixOS configuration
```

Normal host are defined using the `mkHost` function. Whereas `iso` is
manually defined with additional modules needed to be boot-able on a USB stick.

```nix
nixosConfigurations = let
  mkHost = hostname:
    lib.nixosSystem {
      modules = [
        ./hosts/${hostname}/configuration.nix
      ];
      specialArgs = {inherit inputs outputs;};
    };
in {
  iso = lib.nixosSystem {
    modules = [
      "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-plasma5.nix"
      "${nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
      ./hosts/iso/configuration.nix
    ];
    specialArgs = {inherit inputs outputs;};
  };

  ophiuchus = mkHost "ophiuchus";
  targe = mkHost "targe";
};
```

Lastly, `justfile` is *just* used to conveniently build the iso.
