{config, lib, pkgs, ...}:

{
  xdg.configFile = {
    "vscode".source = ./;
  };
}