{ config, lib, pkgs, ... }:

let
  tomlFormat = pkgs.formats.toml {};
  
  # Common theme settings
  commonTheme = {
    hide_ascii = false;
    spacing = 1;
    padding = 0;
    separator = "|";
    
    bar = {
      glyph = "~";
      symbol_open = "(";
      symbol_close = ")";
      hide_delimiters = false;
      visible = true;
    };
    
    box = {
      border = "rounded";
      visible = true;
      inner_margin = {
        x = 2;
        y = 1;
      };
    };
    
    randomize = {
      key_color = false;
      separator_color = false;
    };
    
    palette = {
      visible = false;
    };
  };
  
  roshTheme = commonTheme // {
    key_color = "LightCyan";
    separator_color = "Yellow";
    box.title = "rosh";
    custom_ascii = {
      color = "#BB90B7";
      path = "~/.config/macchina/themes/rosh.ascii";
    };
  };
  
  nixTheme = commonTheme // {
    key_color = "#5277C3";  # NixOS blue
    separator_color = "#7EBAE4";  # NixOS light blue
    box.title = "nix";
    custom_ascii = {
      color = "#5277C3";  # NixOS blue
      path = "~/.config/macchina/themes/nix.ascii";
    };
  };
  
in {
  home.packages = [ pkgs.macchina ];
  
  # Generate TOML configuration files
  xdg.configFile = {
    "macchina/macchina.toml" = {
      # Default configuration using rosh theme
      source = tomlFormat.generate "macchina.toml" {
        theme = "rosh";
        # Add any other global settings here
      };
    };
    
    "macchina/themes/rosh.toml" = {
      source = tomlFormat.generate "rosh.toml" roshTheme;
    };
    
    "macchina/themes/nix.toml" = {
      source = tomlFormat.generate "nix.toml" nixTheme;
    };
    
    # Keep the ASCII art files
    "macchina/themes/rosh.ascii" = {
      source = ./themes/rosh.ascii;
    };
    
    "macchina/themes/nix.ascii" = {
      source = ./themes/nix.ascii;
    };
  };
}