{inputs, ...}: {
  flake.modules.nixos.ghost = {
    imports = with inputs.self.modules.nixos; [
      system-minimal
      hello-world-server
      ssh
    ];
  };
}
