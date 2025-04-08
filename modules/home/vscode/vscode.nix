{config, lib, pkgs, ...}:

{
  home.file = {
    ".config/vscode/init.lua".source = ./init.lua;
    ".config/vscode/lua/config/modes.lua".source = ./lua/config/modes.lua;
    ".config/vscode/lua/config/keybindings.lua".source = ./lua/config/keybindings.lua;
    ".config/vscode/lua/config/utils.lua".source = ./lua/config/utils.lua;
    ".config/vscode/lua/config/mappings.lua".source = ./lua/config/mappings.lua;

    "Library/Application Support/Code - Insiders/User/keybindings.json".source = ./keybindings.json;
  };
}