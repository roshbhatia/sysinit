{
  lib,
  overlay,
  pkgs,
  ...
}:

{
  imports = [
    (import ./colima.nix {
      inherit
        lib
        overlay
        pkgs
        ;
    })
  ];
}
