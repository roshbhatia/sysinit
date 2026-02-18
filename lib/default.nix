{
  lib,
  nixpkgs,
  inputs,
}:

{
  builders = import ./builders.nix { inherit lib nixpkgs inputs; };
  outputBuilders = import ./output-builders.nix { inherit lib; };
}
