{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.sysinit.theme = {
    base16Scheme = mkOption {
      type = types.str;
      default = "catppuccin-mocha";
      description = "Base16 scheme name from pkgs.base16-schemes (e.g., 'black-metal-bathory', 'gruvbox-dark-soft')";
    };

    appearance = mkOption {
      type = types.enum [
        "light"
        "dark"
      ];
      default = "dark";
      description = "Appearance mode (light or dark) — sets Stylix polarity";
    };

    font = {
      monospace = mkOption {
        type = types.str;
        default = "TX-02";
        description = "Monospace font for terminal and editor";
      };

      size = mkOption {
        type = types.float;
        default = 11.0;
        description = "Base font size for UI elements (sketchybar etc); tune per-font as metrics vary";
      };

      icons = mkOption {
        type = types.str;
        default = "Symbols Nerd Font Mono";
        description = "Icon font family for sketchybar nerd glyphs; set to monospace to share vertical metrics";
      };

      iconYOffset = mkOption {
        type = types.int;
        default = 0;
        description = "Vertical offset for icon glyphs in sketchybar (positive = up in sketchybar coords)";
      };

      labelYOffset = mkOption {
        type = types.int;
        default = 0;
        description = "Vertical offset for label text in sketchybar (positive = up in sketchybar coords)";
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
        default = 0.9;
        description = "Opacity level for transparency effects";
      };

      blur = mkOption {
        type = types.int;
        default = 80;
        description = "Background blur amount";
      };
    };
  };

}
