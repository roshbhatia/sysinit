{
  lib,
  nixpkgs,
  inputs,
}:

{
  builders = import ./builders.nix { inherit lib nixpkgs inputs; };
  common = import ./common.nix;
  outputBuilders = import ./output-builders.nix { inherit lib; };
}
