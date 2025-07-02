{
  lib,
  pkgs,
  ...
}:

{
  imports = [
    (import ./colima.nix {
      inherit
        lib
        pkgs
        ;
    })
  ];
}
