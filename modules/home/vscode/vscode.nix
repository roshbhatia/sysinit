{config, lib, pkgs, ...}:

{
  xdg.configFile."vscode" = {
    source = ./.;
    recursive = true;
  };

  home.file = {
    "Library/Application Support/Code - Insiders/User/keybindings.json".source = ./keybindings.json;
    "Library/Application Support/Code - Insiders/User/settings.json".source = ./settings.json;
  };
}