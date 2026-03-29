{self, ...}: {
  config.flake.factory.minecraft-server = {
    slug,
    ports,
    extraEnv,
    ...
  }: {
    nixos."minecraft-${slug}" = {config, ...}: {
      imports = with self.modules.nixos; [minecraft-base sops];

      networking.firewall.allowedTCPPorts = ports;

      sops.secrets = {
        curseForgeToken = {
          sopsFile = ../../../secrets/curseForgeSecrets.env;
          format = "dotenv";
          restartUnits = [
            config.virtualisation.oci-containers.containers."minecraft-server-${slug}".serviceName
          ];
        };
      };

      virtualisation.oci-containers.containers."minecraft-server-${slug}" = {
        image = "ghcr.io/itzg/minecraft-server";
        pull = "newer";
        environment =
          {
            EULA = "TRUE";
            MAX_MEMORY = "16G";
          }
          // extraEnv;
        environmentFiles = [
          config.sops.secrets.curseForgeToken.path
        ];
        ports = map (p: "${toString p}:${toString p}") ports;
        volumes = [
          "/srv/minecraft/servers/${slug}"
        ];
      };
    };
  };
}
