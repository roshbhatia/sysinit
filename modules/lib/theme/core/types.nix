{ lib, ... }:

with lib;

{
  # Core theme type definitions
  themeType = types.submodule {
    options = {
      meta = mkOption {
        type = types.submodule {
          options = {
            name = mkOption {
              type = types.str;
              description = "Human-readable theme name";
            };

            id = mkOption {
              type = types.str;
              description = "Unique theme identifier";
            };

            variants = mkOption {
              type = types.listOf types.str;
              description = "Available theme variants";
            };

            supports = mkOption {
              type = types.listOf (
                types.enum [
                  "dark"
                  "light"
                ]
              );
              default = [ "dark" ];
              description = "Supported appearance modes";
            };

            author = mkOption {
              type = types.str;
              default = "";
              description = "Theme author";
            };

            homepage = mkOption {
              type = types.str;
              default = "";
              description = "Theme homepage URL";
            };
          };
        };
        description = "Theme metadata";
      };

      palettes = mkOption {
        type = types.attrsOf paletteType;
        description = "Color palettes for each variant";
      };

      semanticMapping = mkOption {
        type = types.functionTo semanticColorsType;
        description = "Function to map palette to semantic colors";
      };

      appAdapters = mkOption {
        type = types.attrsOf types.attrs;
        default = { };
        description = "App-specific theme adapters";
      };
    };
  };

  # Color palette type
  paletteType = types.attrsOf types.str;

  # Semantic colors type
  semanticColorsType = types.submodule {
    options = {
      # Core UI colors
      background = mkOption {
        type = types.submodule {
          options = {
            primary = mkOption { type = types.str; };
            secondary = mkOption { type = types.str; };
            tertiary = mkOption { type = types.str; };
            overlay = mkOption { type = types.str; };
          };
        };
      };

      foreground = mkOption {
        type = types.submodule {
          options = {
            primary = mkOption { type = types.str; };
            secondary = mkOption { type = types.str; };
            muted = mkOption { type = types.str; };
            subtle = mkOption { type = types.str; };
          };
        };
      };

      accent = mkOption {
        type = types.submodule {
          options = {
            primary = mkOption { type = types.str; };
            secondary = mkOption { type = types.str; };
            dim = mkOption { type = types.str; };
          };
        };
      };

      # Semantic state colors
      semantic = mkOption {
        type = types.submodule {
          options = {
            success = mkOption { type = types.str; };
            warning = mkOption { type = types.str; };
            error = mkOption { type = types.str; };
            info = mkOption { type = types.str; };
          };
        };
      };

      # Syntax highlighting colors
      syntax = mkOption {
        type = types.submodule {
          options = {
            keyword = mkOption { type = types.str; };
            string = mkOption { type = types.str; };
            number = mkOption { type = types.str; };
            comment = mkOption { type = types.str; };
            function = mkOption { type = types.str; };
            variable = mkOption { type = types.str; };
            type = mkOption { type = types.str; };
            operator = mkOption { type = types.str; };
            constant = mkOption { type = types.str; };
            builtin = mkOption { type = types.str; };
          };
        };
      };

      # Extended color palette for theme-specific needs
      extended = mkOption {
        type = types.attrsOf types.str;
        default = { };
        description = "Theme-specific extended colors";
      };
    };
  };

  # Transparency configuration type
  transparencyType = types.submodule {
    options = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable transparency effects";
      };

      opacity = mkOption {
        type = types.float;
        default = 0.85;
        description = "Opacity level (0.0 - 1.0)";
      };

      blur = mkOption {
        type = types.int;
        default = 0;
        description = "Blur amount for background";
      };
    };
  };

  # Theme configuration type
  themeConfigType = types.submodule {
    options = {
      colorscheme = mkOption {
        type = types.str;
        description = "Selected colorscheme ID";
      };

      variant = mkOption {
        type = types.str;
        description = "Selected variant";
      };

      transparency = mkOption {
        type = transparencyType;
        default = { };
        description = "Transparency configuration";
      };

      presets = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Applied theme presets";
      };

      overrides = mkOption {
        type = types.attrs;
        default = { };
        description = "User-defined color overrides";
      };
    };
  };
}
