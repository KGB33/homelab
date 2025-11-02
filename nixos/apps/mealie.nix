{ ... }:

{
  virtualisation.oci-containers = {
    containers.mealie = {
      image = "ghcr.io/mealie-recipes/mealie:v3.4.0";
      
      autoStart = true;
      
      ports = [
        "9925:9000"
      ];
      
      volumes = [
        "mealie-data:/app/data/"
      ];
      
      environment = {
        ALLOW_SIGNUP = "false";
        TZ = "America/Los_Angeles";
        BASE_URL = "https://mealie.kgb33.dev";
      };
      
      extraOptions = [
        "--memory=1000m"
      ];
    };
  };
}
