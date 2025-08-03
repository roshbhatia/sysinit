{ lib, ... }:

with lib;

let
  # Theme-specific variant mappings (restricted to what you actually use)
  supportedThemeVariants = {
    catppuccin = [ "macchiato" ];
    rose-pine = [ "moon" ];
    gruvbox = [ "dark" ];
    solarized = [ "dark" ];
    nord = [ "dark" ];
    kanagawa = [ "wave" "dragon" ];
  };

  # Get valid variants for a specific theme
  getVariantsForTheme = theme: supportedThemeVariants.${theme} or [];
  
  # All supported themes
  supportedThemes = attrNames supportedThemeVariants;
  
  # All supported variants (flattened)
  allSupportedVariants = unique (flatten (attrValues supportedThemeVariants));

in
{
  # Comprehensive values.nix type definition
  valuesType = types.submodule {
    options = {
      user = mkOption {
        type = types.submodule {
          options = {
            username = mkOption {
              type = types.str;
              description = "System username";
              example = "johndoe";
            };
            
            hostname = mkOption {
              type = types.str;
              description = "System hostname";
              example = "macbook-pro";
            };
          };
        };
        description = "User configuration";
      };

      git = mkOption {
        type = types.submodule {
          options = {
            userName = mkOption {
              type = types.str;
              description = "Git user full name";
              example = "John Doe";
            };
            
            userEmail = mkOption {
              type = types.str;
              description = "Git user email address";
              example = "john@example.com";
            };
            
            githubUser = mkOption {
              type = types.str;
              description = "GitHub username";
              example = "johndoe";
            };
            
            credentialUsername = mkOption {
              type = types.str;
              description = "Git credential helper username";
              example = "johndoe";
            };
          };
        };
        description = "Git configuration";
      };

      homebrew = mkOption {
        type = types.submodule {
          options = {
            additionalPackages = mkOption {
              type = types.submodule {
                options = {
                  taps = mkOption {
                    type = types.listOf types.str;
                    default = [];
                    description = "Additional Homebrew taps to install";
                    example = [ "hashicorp/tap" "homebrew/cask-fonts" ];
                  };
                  
                  brews = mkOption {
                    type = types.listOf types.str;
                    default = [];
                    description = "Additional Homebrew formulae to install";
                    example = [ "wget" "htop" "jq" ];
                  };
                  
                  casks = mkOption {
                    type = types.listOf types.str;
                    default = [];
                    description = "Additional Homebrew casks to install";
                    example = [ "firefox" "discord" "slack" ];
                  };
                };
              };
              default = {};
              description = "Additional Homebrew packages to install";
            };
          };
        };
        default = {};
        description = "Homebrew configuration";
      };

      yarn = mkOption {
        type = types.submodule {
          options = {
            additionalPackages = mkOption {
              type = types.listOf types.str;
              default = [];
              description = "Additional global Yarn packages to install";
              example = [ "@vue/cli" "create-react-app" "typescript" ];
            };
          };
        };
        default = {};
        description = "Yarn configuration";
      };

      cargo = mkOption {
        type = types.submodule {
          options = {
            additionalPackages = mkOption {
              type = types.listOf types.str;
              default = [];
              description = "Additional Cargo packages to install";
              example = [ "ripgrep" "fd-find" "bat" ];
            };
          };
        };
        default = {};
        description = "Cargo (Rust) configuration";
      };

      nix = mkOption {
        type = types.submodule {
          options = {
            packages = mkOption {
              type = types.listOf types.str;
              default = [];
              description = "Additional Nix packages to install";
              example = [ "jq" "fd" "ripgrep" ];
            };
          };
        };
        default = {};
        description = "Nix package configuration";
      };

      krew = mkOption {
        type = types.submodule {
          options = {
            additionalPackages = mkOption {
              type = types.listOf types.str;
              default = [];
              description = "Additional kubectl krew plugins to install";
              example = [ "ctx" "ns" "stern" ];
            };
          };
        };
        default = {};
        description = "Kubectl krew plugin configuration";
      };

      theme = mkOption {
        type = types.submodule {
          options = {
            colorscheme = mkOption {
              type = types.enum supportedThemes;
              description = "Color scheme to use system-wide";
              example = "catppuccin";
            };
            
            variant = mkOption {
              type = types.enum allSupportedVariants;
              description = "Variant of the chosen color scheme";
              example = "macchiato";
            };
            
            transparency = mkOption {
              type = types.submodule {
                options = {
                  enable = mkOption {
                    type = types.bool;
                    default = true;
                    description = "Whether to enable transparency effects";
                  };
                  
                  opacity = mkOption {
                    type = types.float;
                    default = 0.85;
                    description = "Opacity level for transparency effects (0.0 - 1.0)";
                  };
                  
                  blur = mkOption {
                    type = types.int;
                    default = 80;
                    description = "Background blur amount";
                  };
                };
              };
              default = {};
              description = "Transparency configuration";
            };
            
            presets = mkOption {
              type = types.listOf (types.enum [ "none" "light" "medium" "heavy" ]);
              default = [];
              description = "Theme presets to apply";
              example = [ "medium" ];
            };
            
            overrides = mkOption {
              type = types.attrs;
              default = {};
              description = "Custom color overrides";
              example = { accent = "#ff0000"; };
            };
          };
        };
        description = "Theme configuration";
      };

      wezterm = mkOption {
        type = types.submodule {
          options = {
            nvim_transparency_override = mkOption {
              type = types.nullOr (types.submodule {
                options = {
                  enable = mkOption {
                    type = types.bool;
                    description = "Enable transparency when Neovim is running";
                  };
                  
                  opacity = mkOption {
                    type = types.float;
                    description = "Opacity level when Neovim is running";
                  };
                  
                  blur = mkOption {
                    type = types.int;
                    default = 80;
                    description = "Blur amount when Neovim is running";
                  };
                };
              });
              default = null;
              description = "Override transparency settings when Neovim is detected";
              example = {
                enable = true;
                opacity = 0.95;
                blur = 40;
              };
            };
          };
        };
        default = {};
        description = "Wezterm-specific configuration";
      };
    };
  };

  # Export helpful functions
  inherit supportedThemes supportedThemeVariants getVariantsForTheme allSupportedVariants;
  
  # Validation function for theme/variant combinations
  validateThemeVariant = theme: variant:
    if !elem theme supportedThemes then
      throw "Unsupported theme '${theme}'. Supported themes: ${concatStringsSep ", " supportedThemes}"
    else if !elem variant (getVariantsForTheme theme) then
      throw "Unsupported variant '${variant}' for theme '${theme}'. Supported variants: ${concatStringsSep ", " (getVariantsForTheme theme)}"
    else
      true;
}