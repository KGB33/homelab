{den, ...}: {
  den.aspects.system-default.includes = with den.aspects; [
    system-minimal
    podman
    comin
    ssh
  ];
}
