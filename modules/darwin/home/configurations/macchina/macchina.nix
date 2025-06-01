{
  pkgs,
  homeDirectory,
  ...
}:

let
  tomlFormat = pkgs.formats.toml { };

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
      path = "${homeDirectory}/.config/macchina/themes/rosh.ascii";
    };
  };

  nixTheme = commonTheme // {
    key_color = "#5277C3";
    separator_color = "#7EBAE4";
    box.title = "nix";
    custom_ascii = {
      color = "#5277C3";
      path = "${homeDirectory}/.config/macchina/themes/nix.ascii";
    };
  };

  mgsTheme = commonTheme // {
    key_color = "#5277C3";
    separator_color = "#7EBAE4";
    box.title = "nix";
    custom_ascii = {
      color = "#5277C3";
      path = "${homeDirectory}/.config/macchina/themes/mgs.ascii";
    };
  };

in
{
  home.packages = [ pkgs.macchina ];

  xdg.configFile = {
    "macchina/macchina.toml" = {
      source = tomlFormat.generate "macchina.toml" {
        theme = "rosh";
      };
      force = true;
    };

    "macchina/themes/rosh.toml" = {
      source = tomlFormat.generate "rosh.toml" roshTheme;
      force = true;
    };

    "macchina/themes/nix.toml" = {
      source = tomlFormat.generate "nix.toml" nixTheme;
      force = true;
    };

    "macchina/themes/mgs.toml" = {
      source = tomlFormat.generate "mgs.toml" mgsTheme;
      force = true;
    };

    "macchina/themes/rosh.ascii" = {
      source = ./themes/rosh.ascii;
      force = true;
    };

    "macchina/themes/nix.ascii" = {
      source = ./themes/nix.ascii;
      force = true;
    };

    "macchina/themes/mgs.ascii" = {
      source = ./themes/mgs.ascii;
      force = true;
    };
  };
}

