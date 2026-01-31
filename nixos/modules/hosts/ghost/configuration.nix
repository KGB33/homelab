{inputs, ...}: {
  flake.modules.nixos.ghost = {...}: {
    imports = with inputs.self.modules.nixos; [
      system-default
    ];
  };
}
