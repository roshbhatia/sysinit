{ scanLib, pkgs, ... }:
scanLib.mkScanCheck {
  name = "lua-parse";
  root = ../modules;
  unit = "lua files";
  tools = [ pkgs.lua5_4 ];
  findArgs = "-name '*.lua'";
  validate = "luac -p \"$f\"";
  hint = "Fix the module; a parse error drops WezTerm to its defaults.";
  requireNonEmpty = [
    { path = "home/programs/wezterm/lua"; }
    { path = "darwin/home/hammerspoon"; }
    { path = "darwin/home/sketchybar/lua"; }
    { path = "home/programs/neovim/config/lua"; }
  ];
}
