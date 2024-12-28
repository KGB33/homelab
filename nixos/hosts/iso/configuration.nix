{pkgs, ...}: {
  imports = [../../base/configuration.nix];

  networking = {
    hostName = "iso";
  };

  systemd.network = {
    enable = true;
    networks."10-wlan0" = {
      matchConfig.Name = "wlan0";
      networkConfig.DHCP = "yes";
    };
    networks."05-ens0" = {
      matchConfig.Name = "ens0";
      networkConfig.DHCP = "yes";
    };
  };

  environment.systemPackages = with pkgs; [
    gum
    (writeShellScriptBin "nix_installer" (builtins.readFile ./installScript.sh))
    (writeShellScriptBin "clone_repo" (builtins.readFile ./cloneRepo.fish))
  ];
}
