{pkgs, ...}: {
  programs.zsh.enable = true;
  programs.fish.enable = true;

  environment.systemPackages = with pkgs; [
    fd
    git
    nmap
    neovim
    ripgrep
  ];
}
