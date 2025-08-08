{ pkgs, ... }:
{
  imports = [
    (import ./hammerspoon.nix { inherit pkgs; })
  ];
}
