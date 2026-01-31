{ lib, config, ... }:

with lib;

let
  themes = import ./theme { inherit lib; };
  cfg = config.sysinit.theme;

  allVariants = unique (flatten (map (meta: meta.variants) (attrValues themes.metadata)));

in
{
  options.sysinit.theme = {
    colorscheme = mkOption {
      type = types.enum (attrNames themes.metadata);
      default = "rose-pine";
      description = "The color scheme to use system-wide";
    };

    variant = mkOption {
      type = types.enum allVariants;
      default = "moon";
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
        default = 0.7;
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

    appThemes = mkOption {
      type = types.attrs;
      readOnly = true;
      default = {
        neovim = themes.getAppTheme "neovim" cfg.colorscheme cfg.variant;
        wezterm = themes.getAppTheme "wezterm" cfg.colorscheme cfg.variant;
        sketchybar = themes.getAppTheme "sketchybar" cfg.colorscheme cfg.variant;
      };
      description = "App-specific theme names";
    };

    meta = mkOption {
      type = types.attrs;
      readOnly = true;
      default = themes.getThemeInfo cfg.colorscheme;
      description = "Theme metadata";
    };
  };

  config = {
    # Theme configuration is now handled through stylix
    # Colors are accessed via config.lib.stylix.colors
  };
}
