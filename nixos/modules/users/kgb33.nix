{den, ...}: {
  den.aspects.kgb33 = {
    includes = [
      den.batteries.define-user
      (den.batteries.user-shell "fish")
    ];

    user = {
      extraGroups = ["wheel" "docker" "podman" "video" "audio"];
      initialHashedPassword = "$y$j9T$yrzNoVIQKPwFanJ/mq.Ai.$ZRTuPRj5KhWRWhVsymevhgIMe6VY37Io0nVps4coPi8";
      openssh = {
        authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDsItKA/n+4hj/qTtEURIGm3zpoelVwqyUOG88DqPGpB"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJwbBIHzrrJhfKv9vB/+M70HNMd9Kr1B2FqnzYGh/Dfg"
        ];
      };
    };
  };
}
