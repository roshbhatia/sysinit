{ lib, config, ... }:

with lib;

let
  themes = import ./theme { inherit lib; };
  cfg = config.sysinit.theme;

  allVariants = unique (flatten (map (theme: theme.meta.variants) (attrValues themes.themes)));

in
{
  options.sysinit.theme = {
    colorscheme = mkOption {
      type = types.enum (attrNames themes.themes);
      default = "catppuccin";
      description = "The color scheme to use system-wide";
    };

    variant = mkOption {
      type = types.enum allVariants;
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
        default = 0.85;
        description = "Opacity level for transparency effects";
      };

      blur = mkOption {
        type = types.int;
        default = 80;
        description = "Background blur amount";
      };
    };

    presets = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Theme presets to apply";
    };

    overrides = mkOption {
      type = types.attrs;
      default = { };
      description = "Color overrides";
    };

    palette = mkOption {
      type = types.attrs;
      readOnly = true;
      default = themes.getThemePalette cfg.colorscheme cfg.variant;
      description = "Color palette for the current theme";
    };

    semanticColors = mkOption {
      type = types.attrs;
      readOnly = true;
      default = themes.getSemanticColors cfg.colorscheme cfg.variant;
      description = "Semantic color mappings";
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
        vivid = themes.getAppTheme "vivid" cfg.colorscheme cfg.variant;
        sketchybar = themes.getAppTheme "sketchybar" cfg.colorscheme cfg.variant;
      };
      description = "App-specific theme names";
    };

    ansiMappings = mkOption {
      type = types.attrs;
      readOnly = true;
      default =
        if hasAttrByPath [ cfg.colorscheme cfg.variant ] themes.ansiMappings then
          themes.ansiMappings.${cfg.colorscheme}.${cfg.variant}
        else
          throw "ANSI mappings not found for theme '${cfg.colorscheme}' variant '${cfg.variant}'";
      description = "ANSI color mappings for terminal applications";
    };

    meta = mkOption {
      type = types.attrs;
      readOnly = true;
      default = themes.getThemeInfo cfg.colorscheme;
      description = "Theme metadata";
    };
  };

  config = {

    home.file.".config/sysinit/theme_config.json" = {
      text = builtins.toJSON (
        themes.generateAppJSON "neovim" {
          colorscheme = cfg.colorscheme;
          variant = cfg.variant;
          transparency = cfg.transparency;
          presets = cfg.presets;
          overrides = cfg.overrides;
        }
      );
    };
  };
}
