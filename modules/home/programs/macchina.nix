{ config, lib, pkgs, ... }:

{
  # Macchina configuration via xdg paths
  xdg.configFile = {
    "macchina/themes/rosh.toml" = {
      text = ''        
        hide_ascii      = false
        spacing         = 1
        padding         = 0
        separator       = ""
        key_color       = "LightCyan"
        separator_color = "Yellow"
        
        [bar]
        glyph           = " "
        symbol_open     = "("
        symbol_close    = ")"
        hide_delimiters = false
        visible         = false
        
        [box]
        title           = "rosh"
        border          = "rounded"
        visible         = true
        
        [box.inner_margin]
        x               = 2
        y               = 1
        
        [custom_ascii]
        color           = "#BB90B7"
        path            = "~/.config/macchina/themes/rosh.ascii"
        
        [randomize]
        key_color       = false
        separator_color = false
        
        [palette]
        type            = "Dark"
        visible         = true
        glyph           = "   "
        
        [keys]
        host            = "  host"
        kernel          = "󰌽  kernel"
        battery         = "󰁹  battery"
        os              = "  os"
        de              = "  de"
        wm              = "  wm"
        distro          = "  distro"
        terminal        = "  terminal"
        shell           = "  shell"
        packages        = "  packages"
        uptime          = "󰥔  uptime"
        memory          = "  memory"
        machine         = "󰇅  machine"
        local_ip        = "󰱓  ip"
      '';
    };
    
    "macchina/themes/rosh.ascii" = {
      source = ../../../macchina/themes/rosh.ascii;
    };
  };
}
