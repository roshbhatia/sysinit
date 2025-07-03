{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    (import ./treesitter.nix {
      inherit
        config
        lib
        pkgs
        ;
    })
  ];
}
