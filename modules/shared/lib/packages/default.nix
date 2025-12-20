{
  lib,
  pkgs,
  ...
}:

import ./lib.nix { inherit lib pkgs; }
