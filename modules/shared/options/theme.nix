{ lib, config, ... }:

with lib;

let
  themes = import ../../lib/theme.nix { inherit lib; };
  cfg = config.sysinit.theme;
  metadata = themes.metadata;

  allVariants = unique (flatten (map (meta: meta.variants) (attrValues metadata)));

in
{
  options.sysinit.theme = {
    appearance = mkOption {
      type = types.enum [
        "light"
        "dark"
      ];
      default = "dark";
      description = "Appearance mode (light or dark)";
    };

    colorscheme = mkOption {
      type = types.enum (attrNames metadata);
      default = "rose-pine";
      description = "The color scheme to use system-wide";
    };

    variant = mkOption {
      type = types.enum allVariants;
      default = "moon";
      description = "The variant of the chosen color scheme";
    };

    font = {
      monospace = mkOption {
        type = types.str;
        default = "TX-02";
        description = "Monospace font for terminal and editor";
      };

      symbols = mkOption {
        type = types.str;
        default = "Symbols Nerd Font";
        readOnly = true;
        description = "Fallback font for nerd font glyphs (always Symbols Nerd Font)";
      };
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
      default = metadata.${cfg.colorscheme} or { };
      description = "Theme metadata";
    };
  };

}
