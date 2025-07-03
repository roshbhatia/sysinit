{
  lib,
  pkgs,
  ...
}:

{
  imports = [
    (import ./treesitter.nix {
      inherit
        lib
        pkgs
        ;
    })
  ];
}

