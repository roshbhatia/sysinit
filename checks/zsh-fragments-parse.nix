{ scanLib, pkgs, ... }:
scanLib.mkScanCheck {
  name = "zsh-fragments-parse";
  root = ../modules;
  unit = "zsh fragments";
  tools = [ pkgs.zsh ];
  findArgs = "-name '*.zsh'";
  validate = "zsh -n \"$f\"";
  hint = "Fix the fragment; it is interpolated into every interactive shell.";
  requireNonEmpty = [ { path = "home/programs/zsh"; } ];
}
