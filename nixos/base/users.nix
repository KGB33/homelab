{pkgs, ...}: {
  users.users.kgb33 = {
    isNormalUser = true;
    description = "Kelton";
    extraGroups = ["wheel" "docker" "video" "audio"];
    shell = pkgs.fish;
    initialHashedPassword = "$y$j9T$yrzNoVIQKPwFanJ/mq.Ai.$ZRTuPRj5KhWRWhVsymevhgIMe6VY37Io0nVps4coPi8";
    openssh = {
      authorizedKeys.keys = [
        # curl -s https://github.com/KGB33.keys
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDsItKA/n+4hj/qTtEURIGm3zpoelVwqyUOG88DqPGpB"
      ];
    };
  };
}
