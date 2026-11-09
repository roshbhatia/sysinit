{ lib }:
let
  root = ./.;
  package = import ../lib/skill-package.nix { inherit lib root; };
  directories = lib.filterAttrs (name: type: type == "directory" && !(lib.hasPrefix "_" name)) (
    builtins.readDir root
  );
in
lib.mapAttrs package.load directories
