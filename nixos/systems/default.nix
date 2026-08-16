{ den, ... }: {
  den.aspects.system-default.includes = with den.aspects; [
    system-minimal
    otelcol
    podman
    comin
    ssh
  ];
}
