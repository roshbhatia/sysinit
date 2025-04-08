{config, lib, pkgs, ...}:

{
  xdg.configFile."vscode/init.lua".source = ./init.lua;
}