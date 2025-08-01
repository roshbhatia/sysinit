{
  config,
  lib,
  pkgs,
  values,
  ...
}:
{
  imports = [
    (import ./helix.nix {
      inherit
        config
        lib
        pkgs
        values
        ;
    })
  ];
}
