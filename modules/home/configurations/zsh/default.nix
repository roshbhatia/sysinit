{
  config,
  lib,
  values,
  pkgs,
  ...
}:
{
  imports = [
    (import ./zsh.nix {
      inherit
        config
        lib
        values
        pkgs
        ;
    })
  ];
}
