{config, lib, pkgs, ...}:

{
  xdg.configFile = {
    # Main init file
    "vscode/init.lua".source = ./init.lua;
    
    # Config modules
    "vscode/lua/config/modes.lua".source = ./lua/config/modes.lua;
    "vscode/lua/config/keybindings.lua".source = ./lua/config/keybindings.lua;
    "vscode/lua/config/utils.lua".source = ./lua/config/utils.lua;
    "vscode/lua/config/mappings.lua".source = ./lua/config/mappings.lua;
  };
}