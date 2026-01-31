{inputs, ...}: {
  flake.modules.nixos.system-default = {...}: {
    imports = with inputs.self.modules.nixos; [
      system-minimal
      user-kgb33
      ssh
    ];
  };
}
