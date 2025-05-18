{
  config,
  inputs,
  ...
}: {
  sops.secrets = {
    "DISCORD_TOKEN" = {
      sopsFile = ../secrets/roboShpeeSecrets.env;
      format = "dotenv";
      restartUnits = [
        config.systemd.services.roboShpee.name
      ];
    };
  };
  systemd.services.roboShpee = {
    enable = true;
    wants = ["network.target"];
    serviceConfig = {
      ExecStart = "${inputs.roboshpee.packages.x86_64-linux.roboshpee}/bin/roboshpee";
      Type = "simple";
      Restart = "on-failure";
      EnvironmentFile = config.sops.secrets.DISCORD_TOKEN.path;
    };
  };
}
