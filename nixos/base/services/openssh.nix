{...}: {
  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      UseDns = true;
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };
}
