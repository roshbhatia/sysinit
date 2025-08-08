{ config, pkgs, ... }:
{
  imports = [
    (import ./hammerspoon.nix { inherit config pkgs; })
  ];
}
