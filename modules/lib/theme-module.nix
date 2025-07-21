# Theme Module - Centralizes theme configuration and provides it to other modules
{ lib, config, ... }:

with lib;

let
  themes = import ./themes { inherit lib; };
  cfg = config.sysinit.theme;
in
{
  options.sysinit.theme = {
    colorscheme = mkOption {
      type = types.enum [
        "catppuccin"
        "rose-pine"
        "gruvbox"
        "solarized"
      ];
      default = "catppuccin";
      description = "The color scheme to use system-wide";
    };

    variant = mkOption {
      type = types.str;
      default = "macchiato";
      description = "The variant of the chosen color scheme";
    };

    transparency = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable transparency effects";
      };

      opacity = mkOption {
        type = types.float;
        default = 0.9;
        description = "Opacity level for transparency effects";
      };
    };

    # Computed values - these are derived from the user's choices
    palette = mkOption {
      type = types.attrs;
      readOnly = true;
      default = themes.getThemePalette cfg.colorscheme cfg.variant;
      description = "Color palette for the current theme";
    };

    appThemes = mkOption {
      type = types.attrs;
      readOnly = true;
      default = {
        neovim = themes.getAppTheme "neovim" cfg.colorscheme cfg.variant;
        wezterm = themes.getAppTheme "wezterm" cfg.colorscheme cfg.variant;
        bat = themes.getAppTheme "bat" cfg.colorscheme cfg.variant;
        git = themes.getAppTheme "delta" cfg.colorscheme cfg.variant;
        atuin = themes.getAppTheme "atuin" cfg.colorscheme cfg.variant;
      };
      description = "App-specific theme names";
    };

    ansiMappings = mkOption {
      type = types.attrs;
      readOnly = true;
      default =
        themes.ansiMappings.${cfg.colorscheme}.${cfg.variant} or themes.ansiMappings.catppuccin.macchiato;
      description = "ANSI color mappings for terminal applications";
    };
  };

  config = {
    # This module doesn't generate any config itself, it just provides options
    # Other modules can access theme information via config.sysinit.theme.*
  };
}

