{
  lib,
  values,
  pkgs,
  ...
}:
{
  imports = [
    (import ./borders.nix {
      inherit
        lib
        values
        pkgs
        ;
    })
  ];
}

