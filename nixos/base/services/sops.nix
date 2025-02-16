{...}: {
  sops = {
    defaultSopsFormat = "yaml";

    age.keyFile = "/home/kgb33/.config/sops/age/keys.txt";
  };
}
