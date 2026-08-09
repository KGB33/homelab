{den, ...}: {
  den.aspects.ghost.includes =
    [den.batteries.hostname]
    ++ (with den.aspects; [system-default]);
}
