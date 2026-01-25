{
  config,
  pkgs,
  values,
  lib,
  utils,
  ...
}:

let
  # === Wezterm ===
  themes = import ../shared/lib/theme.nix { inherit lib; };
  themeNames = import ../shared/lib/theme/adapters/theme-names.nix { inherit lib; };
  weztermThemeName = themeNames.getWeztermTheme values.theme.colorscheme values.theme.variant;

  # === Macchina ===
  inherit (utils.theme) mkThemedConfig;

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
  # === Wezterm: Terminal emulator ===
  stylix.targets.wezterm.enable = false;

  xdg.configFile = {
    "wezterm/wezterm.lua".source = ./configurations/wezterm/wezterm.lua;
    "wezterm/lua".source = ./configurations/wezterm/lua;
    "wezterm/config.json".text = themes.toJsonFile (
      themes.makeThemeJsonConfig values {
        color_scheme = weztermThemeName;
      }
    );
    "wezterm/colors/kanso-ink.lua".source = ./configurations/wezterm/colors/kanso-ink.lua;
    "wezterm/colors/kanso-mist.lua".source = ./configurations/wezterm/colors/kanso-mist.lua;

    # === Macchina: System info fetcher ===
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
      source = ./configurations/macchina/themes/rosh.ascii;
      force = true;
    };

    "macchina/themes/rosh-color.ascii" = {
      source = ./configurations/macchina/themes/rosh-color.ascii;
      force = true;
    };

    "macchina/themes/nix.ascii" = {
      source = ./configurations/macchina/themes/nix.ascii;
      force = true;
    };

    "macchina/themes/mgs.ascii" = {
      source = ./configurations/macchina/themes/mgs.ascii;
      force = true;
    };

    "macchina/themes/varre.ascii" = {
      source = ./configurations/macchina/themes/varre.ascii;
      force = true;
    };
  };

  # === Btop: System monitor ===
  programs.btop = {
    enable = true;
    settings = {
      vim_keys = true;
      force_tty = true;
      theme_background = false;
      shown_boxes = "cpu proc";
    };
  };

  # === Hushlogin: Suppress login message ===
  home.file.".hushlogin" = {
    text = "";
    force = true;
  };

  # === 1Password: Password manager CLI ===
  programs.ssh = {
    extraConfig = ''
      IdentityAgent ~/.1password/agent.sock
    '';
  };
}
