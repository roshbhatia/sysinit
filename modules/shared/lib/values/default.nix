{ lib }:

with lib;
{
  valuesType = types.submodule {
    options = {
      config = {
        root = mkOption {
          type = types.path;
          description = "Root path to the configuration flake directory";
        };
      };

      user = {
        username = mkOption {
          type = types.str;
          default = "user";
          description = "Username for the system user";
        };

        # no default for hostname here. this should just be set upstream anyways
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

      nixos = {
        desktop = {
          # should always be wayland
          displayServer = mkOption {
            type = types.enum [
              "x11"
              "wayland"
            ];
            default = "x11";
            description = "Display server to use (X11 or Wayland)";
          };
          # idk here but hwatever is used by hyprland
          desktopEnvironment = mkOption {
            type = types.enum [
              "gnome"
              "kde"
              "sway"
              "xfce"
            ];
            default = "gnome";
            description = "Desktop environment to use";
          };
        };

        # not needed. always will be nvidia for now.
        gpu = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable GPU support";
          };

          vendor = mkOption {
            type = types.enum [
              "nvidia"
              "amd"
              "intel"
              "none"
            ];
            default = "none";
            description = "GPU vendor";
          };
        };
        # not needed. audio is always going to be enabled. choose one between pipewire and pulseaudio
        audio = {
          enable = mkOption {
            type = types.bool;
            default = true;
            description = "Enable audio support";
          };

          server = mkOption {
            type = types.enum [
              "pipewire"
              "pulseaudio"
            ];
            default = "pipewire";
            description = "Audio server to use";
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
          default = "catppuccin";
          description = "Theme colorscheme";
        };

        variant = mkOption {
          type = types.str;
          default = "macchiato";
          description = "Theme variant";
        };

        presets = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Theme presets to apply (e.g., transparency)";
        };

        overrides = mkOption {
          type = types.attrsOf types.anything;
          default = { };
          description = "Theme color overrides";
        };

        font = {
          monospace = mkOption {
            type = types.str;
            default = "Fantasma";
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
            default = 0.8;
            description = "Transparency opacity level";
          };

          blur = mkOption {
            type = types.int;
            default = 80;
            description = "Background blur amount";
          };
        };
      };

      llm = {
        mcp = {
          servers = mkOption {
            type = types.attrsOf (types.attrsOf types.anything);
            default = { };
            description = "MCP servers configuration";
          };
        };

        agents = {
          opencode = mkOption {
            type = types.bool;
            default = true;
            description = "Enable Opencode AI agent";
          };

          claude = mkOption {
            type = types.bool;
            default = true;
            description = "Enable Claude AI agent";
          };

          amp = mkOption {
            type = types.bool;
            default = true;
            description = "Enable Amp AI agent";
          };

          goose = mkOption {
            type = types.bool;
            default = true;
            description = "Enable Goose AI agent";
          };

          cursor = mkOption {
            type = types.bool;
            default = true;
            description = "Enable Cursor AI agent";
          };

          copilot = mkOption {
            type = types.bool;
            default = true;
            description = "Enable GitHub Copilot";
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
