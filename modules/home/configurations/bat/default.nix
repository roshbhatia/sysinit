{
  lib,
  values,
  utils,
  ...
}:
{
  imports = [
    (import ./bat.nix {
      inherit lib values utils;
    })
  ];
}
