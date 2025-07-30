{
  config,
  lib,
  values,
  pkgs,
  ...
}:
{
  imports = [
    (import ./nu.nix {
      inherit
        config
        lib
        values
        pkgs
        ;
    })
  ];
}
