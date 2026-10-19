{ den, ... }: {
  den.aspects.system-default.includes = with den.aspects; [
    system-minimal
    otelcol
    podman
    comin
    ssh
  ];

  den.aspects.system-default.nixos = {
    services.resolved = {
      enable = true;
      settings.Resolve = {
        DNS = [ "10.0.9.100" ];
        Domains = [ "~kgb33.dev" ];
      };
    };
  };
}
