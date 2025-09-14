{
  config,
  pkgs,
  values,
  utils,
  ...
}:

let
  inherit (utils.themes) mkThemedConfig;
  themeCfg = mkThemedConfig values "macchina" { };
  semanticColors = themeCfg.themes.getSemanticColors values.theme.colorscheme values.theme.variant;

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
    key_color = semanticColors.foreground.primary;
    separator_color = semanticColors.accent.secondary;
    box = {
      title = "rosh";
    };
    custom_ascii = {
      color = semanticColors.accent.primary;
      path = "${config.home.homeDirectory}/.config/macchina/themes/rosh.ascii";
    };
  };

  roshColorTheme = commonTheme // {
    key_color = semanticColors.foreground.primary;
    separator_color = semanticColors.accent.secondary;
    box = {
      title = "rosh";
    };
    custom_ascii = {
      path = "${config.home.homeDirectory}/.config/macchina/themes/rosh-color.ascii";
    };
  };

  nixTheme = commonTheme // {
    key_color = semanticColors.foreground.primary;
    separator_color = semanticColors.accent.secondary;
    box = {
      title = "rosh";
    };
    custom_ascii = {
      color = semanticColors.accent.primary;
      path = "${config.home.homeDirectory}/.config/macchina/themes/nix.ascii";
    };
  };

  mgsTheme = commonTheme // {
    key_color = semanticColors.foreground.primary;
    separator_color = semanticColors.accent.secondary;
    box = {
      title = "rosh";
    };
    custom_ascii = {
      color = semanticColors.accent.primary;
      path = "${config.home.homeDirectory}/.config/macchina/themes/mgs.ascii";
    };
  };

  varreTheme = commonTheme // {
    key_color = semanticColors.foreground.primary;
    separator_color = semanticColors.accent.secondary;
    box = {
      title = "rosh";
    };
    custom_ascii = {
      color = semanticColors.accent.primary;
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
