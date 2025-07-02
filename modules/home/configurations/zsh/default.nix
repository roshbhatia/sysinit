{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    (import ./zsh.nix {
      inherit
        config
        lib
        pkgs
        ;
    })
  ];
}
