{
  lib,
  pkgs,
  values,
  utils,
  ...
}:
{
  imports = [
    (import ./bat.nix {
      inherit lib pkgs values utils;
    })
  ];
}
