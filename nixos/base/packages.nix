{pkgs, ...}: {
  programs.zsh.enable = true;
  programs.fish.enable = true;

  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "updateSystem" "sudo nixos-rebuild switch --flake /home/kgb33/homelab/nixos#`hostname`")
    fd
    git
    nmap
    neovim
    ripgrep
  ];
}
