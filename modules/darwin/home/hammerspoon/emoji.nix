{ pkgs }:

pkgs.runCommand "sysinit-emoji.json"
  {
    nativeBuildInputs = [ pkgs.python3 ];
    src = pkgs.elephant.src;
  }
  ''
    python3 ${./emoji-data.py} "$src" "$out"
  ''
