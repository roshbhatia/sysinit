{
  config,
  lib,
  values,
  ...
}:
{
  imports = [
    (import ./hammerspoon.nix { inherit config lib values; })
  ];
}

