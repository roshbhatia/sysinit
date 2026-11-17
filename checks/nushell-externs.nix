{ lib, pkgs }:
let
  nushellLib = import ../modules/home/programs/nushell/lib.nix { inherit lib; };
in
pkgs.runCommand "nushell-externs"
  {
    nativeBuildInputs = [
      pkgs.nushell
      pkgs.coreutils
      pkgs.git
    ];
  }
  ''
    nu --no-config-file ${./nushell-externs.nu} ${nushellLib.externs pkgs} \
      ${./fixtures/nushell-extern-command.nu} ${./fixtures/nushell-extern-cases.nuon}
    touch "$out"
  ''
