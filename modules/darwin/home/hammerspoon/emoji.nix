{ pkgs }:

pkgs.runCommand "sysinit-emoji.json"
  {
    nativeBuildInputs = [ pkgs.nushell ];
    src = pkgs.elephant.src;
  }
  ''
    nu --no-config-file ${./emoji-data.nu} "$src" "$out"
  ''
