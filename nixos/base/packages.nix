{
  pkgs,
  inputs,
  ...
}: {
  programs.zsh.enable = true;
  programs.fish.enable = true;

  environment.systemPackages = with pkgs; [
    fd
    git
    nmap
    neovim
    ripgrep
    inputs.isd.packages."x86_64-linux".default
  ];
}
