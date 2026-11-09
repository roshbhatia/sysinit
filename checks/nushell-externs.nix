{ lib, pkgs }:
let
  nushellLib = import ../modules/home/programs/nushell/lib.nix { inherit lib; };
in
pkgs.runCommand "nushell-externs"
  {
    nativeBuildInputs = [
      pkgs.nushell
      pkgs.python3
      pkgs.git
    ];
  }
  ''
    python3 ${./nushell-externs.py} ${lib.getExe pkgs.nushell} ${nushellLib.externs pkgs}
    touch "$out"
  ''
