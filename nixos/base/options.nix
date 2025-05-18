{lib, ...}:
with lib; {
  options.shared = mkOption {
    type = types.attrs;
    readOnly = true;
    default = rec {
      monitoring = {
        loki = {
          hostName = "ophiuchus.internal";
          httpPort = 3030;
          grpcPort = 9096;
        };
        mimir = {
          hostName = "ophiuchus.internal";
          httpPort = 9009;
          grpcPort = 9097;
        };
        tempo = {
          hostName = "ophiuchus.internal";
          httpPort = 3031;
          grpcPort = 9095;
          serverHttpPort = 9878;
          serverGrpcPort = 9879;
        };
      };

      hosts = {
        ophiuchus = {
          hostId = "e7ea22a6"; # `head -c4 /dev/urandom | od -A none -t x4`
          ipv4 = "10.0.9.104";
          ipv4Mask = "24";
        };
        targe = {
          hostId = "5768368a";
          ipv4 = "10.0.9.102";
          ipv4Mask = "24";
        };
      };

      hostMappings =
        mapAttrs' (
          host: values: {
            name = values.ipv4;
            value = ["${host}.internal" "${host}.kgb33.dev"];
          }
        )
        hosts;
    };
  };
}
