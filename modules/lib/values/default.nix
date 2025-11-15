{ lib }:

with lib;

{
  valuesType = types.submodule {
    options = {
      user = {
        username = mkOption {
          type = types.str;
          default = "user";
          description = "Username for the system user";
        };

        hostname = mkOption {
          type = types.str;
          default = "nixos";
          description = "System hostname";
        };
      };

      git = {
        name = mkOption {
          type = types.str;
          description = "Git user name";
        };

        email = mkOption {
          type = types.str;
          description = "Git user email";
        };

        username = mkOption {
          type = types.str;
          description = "Git/GitHub username";
        };

        personalEmail = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Personal email override";
        };

        workEmail = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Work email override";
        };

        personalUsername = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Personal username override";
        };

        workUsername = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Work username override";
        };
      };

      darwin = {
        docker = {
          enable = mkOption {
            type = types.bool;
            default = true;
            description = "Enable container runtime";
          };
        };

        tailscale = {
          enable = mkOption {
            type = types.bool;
            default = true;
            description = "Enable Tailscale";
          };
        };

        borders = {
          enable = mkOption {
            type = types.bool;
            default = true;
            description = "Enable window borders";
          };
        };

        homebrew = {
          additionalPackages = {
            taps = mkOption {
              type = types.listOf types.str;
              default = [ ];
              description = "Additional Homebrew taps";
            };

            brews = mkOption {
              type = types.listOf types.str;
              default = [ ];
              description = "Additional Homebrew formulae";
            };

            casks = mkOption {
              type = types.listOf types.str;
              default = [ ];
              description = "Additional Homebrew casks";
            };
          };
        };
      };

      yarn = {
        additionalPackages = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Additional global yarn packages";
        };
      };

      theme = {
        appearance = mkOption {
          type = types.enum [
            "light"
            "dark"
          ];
          default = "dark";
          description = "Appearance mode (light or dark)";
        };

        colorscheme = mkOption {
          type = types.str;
          default = "rose-pine";
          description = "Theme colorscheme";
        };

        variant = mkOption {
          type = types.str;
          default = "moon";
          description = "Theme variant";
        };

        font = {
          monospace = mkOption {
            type = types.str;
            default = "TX-02";
            description = "Monospace font for terminal and editor";
          };

          nerdfontFallback = mkOption {
            type = types.str;
            default = "Symbols Nerd Font";
            description = "Fallback font for nerd font glyphs";
          };
        };

        transparency = {
          enable = mkOption {
            type = types.bool;
            default = true;
            description = "Enable transparency effects";
          };

          opacity = mkOption {
            type = types.float;
            default = 0.5;
            description = "Transparency opacity level";
          };

          blur = mkOption {
            type = types.int;
            default = 0;
            description = "Background blur amount";
          };
        };
      };

      wezterm = {
        shell = mkOption {
          type = types.str;
          default = "zsh";
          description = "Default shell for wezterm";
        };
      };

      llm = {
        goose = {
          provider = mkOption {
            type = types.str;
            default = "github_copilot";
            description = "Goose provider configuration";
          };

          leadModel = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Goose lead model configuration";
          };

          model = mkOption {
            type = types.str;
            default = "gpt-4o-mini";
            description = "Goose model configuration";
          };
        };
      };

      uvx = {
        additionalPackages = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Additional global uvx packages";
        };
      };

      pipx = {
        additionalPackages = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Additional global pipx packages";
        };
      };

      krew = {
        additionalPackages = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Additional kubectl krew plugins";
        };
      };

      npm = {
        additionalPackages = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Additional global npm packages";
        };
      };

      gh = {
        additionalPackages = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Additional GitHub CLI extensions";
        };
      };

      go = {
        additionalPackages = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Additional Go packages";
        };
      };

      cargo = {
        additionalPackages = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Additional Rust/Cargo packages";
        };
      };

      nix = {
        additionalPackages = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Additional Nix packages";
        };
      };

      vet = {
        additionalPackages = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Additional Vet packages";
        };
      };

      firefox = {
        searchEngines = mkOption {
          type = types.attrsOf (
            types.submodule {
              options = {
                urls = mkOption {
                  type = types.listOf (
                    types.submodule {
                      options = {
                        template = mkOption {
                          type = types.str;
                          description = "URL template for the search engine";
                        };
                        params = mkOption {
                          type = types.listOf (
                            types.submodule {
                              options = {
                                name = mkOption {
                                  type = types.str;
                                  description = "Parameter name";
                                };
                                value = mkOption {
                                  type = types.str;
                                  description = "Parameter value";
                                };
                              };
                            }
                          );
                          default = [ ];
                          description = "URL parameters";
                        };
                      };
                    }
                  );
                  description = "List of URLs for the search engine";
                };
                icon = mkOption {
                  type = types.nullOr types.str;
                  default = null;
                  description = "Icon URL for the search engine";
                };
                updateInterval = mkOption {
                  type = types.nullOr types.int;
                  default = null;
                  description = "Update interval in milliseconds";
                };
                definedAliases = mkOption {
                  type = types.listOf types.str;
                  default = [ ];
                  description = "Search aliases";
                };
              };
            }
          );
          default = { };
          description = "Additional Firefox search engines";
        };
      };
    };
  };
}
