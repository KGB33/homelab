{pkgs, ...}: {
  users.users.kgb33 = {
    isNormalUser = true;
    description = "Kelton";
    extraGroups = ["wheel" "docker" "video" "audio"];
    shell = pkgs.fish;
    initialHashedPassword = "$y$j9T$yrzNoVIQKPwFanJ/mq.Ai.$ZRTuPRj5KhWRWhVsymevhgIMe6VY37Io0nVps4coPi8";
  };
}
