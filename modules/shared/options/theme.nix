{ lib, ... }:

with lib;

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
