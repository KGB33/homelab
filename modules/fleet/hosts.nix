{ lib, ... }:
{
  den.hosts.x86_64-linux = lib.genAttrs [ "ophiuchus" "targe" "tower" ] (_: {
    users.kgb33 = { };
  });
}
