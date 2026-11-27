{ pkgs }:
pkgs.runCommand "onepassword-nushell"
  {
    nativeBuildInputs = [
      pkgs.nushell
      pkgs.coreutils
    ];
  }
  ''
    nu --no-config-file ${./onepassword.nu} \
      ${../../features/nushell/onepassword.nu} ${../fixtures/onepassword-command.nu}
    touch "$out"
  ''
