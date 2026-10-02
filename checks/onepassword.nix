{ pkgs }:
pkgs.runCommand "onepassword-nushell" { } ''
  ${pkgs.python3}/bin/python3 ${./onepassword.py} \
    ${../modules/home/programs/nushell/onepassword.nu} ${pkgs.nushell}/bin/nu
  touch "$out"
''
