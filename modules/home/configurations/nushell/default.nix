{
  config,
  lib,
  values,
  pkgs,
  ...
}:
{
  imports = [
    (import ./nushell.nix {
      inherit
        config
        lib
        values
        pkgs
        ;
    })
  ];
}
