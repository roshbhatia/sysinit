{
  config,
  pkgs,
  values,
  utils,
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

  # Use stylix base16 colors directly
  roshTheme = commonTheme // {
    key_color = "#${config.lib.stylix.colors.base05}"; # Foreground
    separator_color = "#${config.lib.stylix.colors.base0C}"; # Cyan (accent secondary)
    box = {
      title = "rosh";
    };
    custom_ascii = {
      color = "#${config.lib.stylix.colors.base0D}"; # Blue (accent primary)
      path = "${config.home.homeDirectory}/.config/macchina/themes/rosh.ascii";
    };
  };

  roshColorTheme = commonTheme // {
    key_color = "#${config.lib.stylix.colors.base05}";
    separator_color = "#${config.lib.stylix.colors.base0C}";
    box = {
      title = "rosh";
    };
    custom_ascii = {
      path = "${config.home.homeDirectory}/.config/macchina/themes/rosh-color.ascii";
    };
  };

  nixTheme = commonTheme // {
    key_color = "#${config.lib.stylix.colors.base05}";
    separator_color = "#${config.lib.stylix.colors.base0C}";
    box = {
      title = "rosh";
    };
    custom_ascii = {
      color = "#${config.lib.stylix.colors.base0D}";
      path = "${config.home.homeDirectory}/.config/macchina/themes/nix.ascii";
    };
  };

  mgsTheme = commonTheme // {
    key_color = "#${config.lib.stylix.colors.base05}";
    separator_color = "#${config.lib.stylix.colors.base0C}";
    box = {
      title = "rosh";
    };
    custom_ascii = {
      color = "#${config.lib.stylix.colors.base0D}";
      path = "${config.home.homeDirectory}/.config/macchina/themes/mgs.ascii";
    };
  };

  varreTheme = commonTheme // {
    key_color = "#${config.lib.stylix.colors.base05}";
    separator_color = "#${config.lib.stylix.colors.base0C}";
    box = {
      title = "rosh";
    };
    custom_ascii = {
      color = "#${config.lib.stylix.colors.base0D}";
      path = "${config.home.homeDirectory}/.config/macchina/themes/varre.ascii";
    };
  };
in
{
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

    "macchina/themes/rosh-color.toml" = {
      source = tomlFormat.generate "rosh-coloro.toml" roshColorTheme;
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

    "macchina/themes/varre.toml" = {
      source = tomlFormat.generate "varre.toml" varreTheme;
      force = true;
    };

    "macchina/themes/rosh.ascii" = {
      source = ./themes/rosh.ascii;
      force = true;
    };

    "macchina/themes/rosh-color.ascii" = {
      source = ./themes/rosh-color.ascii;
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

    "macchina/themes/varre.ascii" = {
      source = ./themes/varre.ascii;
      force = true;
    };
  };
}
