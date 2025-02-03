{
  lib,
  options,
  ...
}:
with lib; {
  options.shared = mkOption {
    type = types.attrs;
    readOnly = true;
    default = rec {
      monitoring = {
        loki = {
          hostName = "ophiuchus";
          httpPort = 3030;
          grpcPort = 9096;
        };
        mimir = {
          hostName = "ophiuchus";
          httpPort = 9009;
        };
      };

      hosts = {
        ophiuchus = {
          hostId = "e7ea22a6"; # `head -c4 /dev/urandom | od -A none -t x4`
          ipv4 = "10.0.9.104/24";
        };
      };

      hostMappings =
        mapAttrs' (
          host: values: {
            name = values.ipv4;
            value = ["${host}" "${host}.kgb33.dev"];
          }
        )
        hosts;
    };
  };
}
