{ inputs, den, ... }:
{
  imports = [ (inputs.den.namespace "disk" false) ];
}
