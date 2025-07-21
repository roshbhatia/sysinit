{
  config,
  lib,
  overlay,
  pkgs,
  ...
}:
{
  imports = [
    (import ./zsh.nix {
      inherit config lib overlay pkgs;
    })
  ];
}
