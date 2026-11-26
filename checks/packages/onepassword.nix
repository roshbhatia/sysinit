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
      ${../../modules/home/programs/nushell/onepassword.nu} ${../fixtures/onepassword-command.nu}
    touch "$out"
  ''
