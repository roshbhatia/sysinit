{ pkgs }:
pkgs.runCommand "nh-darwin-output-path" { nativeBuildInputs = [ pkgs.python3 ]; } (
  if pkgs.stdenv.hostPlatform.isDarwin then
    ''
      python3 ${./nh.py} ${pkgs.nh}/bin/nh
      touch "$out"
    ''
  else
    ''
      touch "$out"
    ''
)
