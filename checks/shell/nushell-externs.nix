{ lib, pkgs }:
let
  nushellLib = import ../../modules/home/programs/nushell/lib.nix { inherit lib; };
in
import ../lib/nushell.nix { inherit pkgs; } {
  name = "nushell-externs";
  script = ./nushell-externs.nu;
  inputs = [ pkgs.git ];
  arguments = [
    (nushellLib.externs pkgs)
    ../fixtures/nushell-extern-command.nu
    ../fixtures/nushell-extern-cases.nuon
  ];
}
