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

      tailscale = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable Tailscale";
        };
      };

      nix = {
        additionalPackages = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Additional Nix packages";
        };
      };

      darwin = {
        borders = {
          enable = mkOption {
            type = types.bool;
            default = true;
            description = "Enable window borders";
          };
        };

        dock = {
          entries = mkOption {
            type = types.listOf (
              types.submodule {
                options = {
                  path = mkOption {
                    type = types.str;
                    description = "Path to application or item for dock";
                  };
                  section = mkOption {
                    type = types.enum [
                      "apps"
                      "others"
                    ];
                    default = "apps";
                    description = "Dock section (apps or others)";
                  };
                  options = mkOption {
                    type = types.str;
                    default = "";
                    description = "Additional dockutil options";
                  };
                };
              }
            );
            default = [
              { path = "/System/Applications/Finder.app"; }
              { path = "/Applications/1Password 7 - Password Manager.app"; }
              { path = "/System/Applications/Music.app"; }
              { path = "/Applications/Audible.app"; }
              { path = "/Applications/Books.app"; }
              { path = "/Applications/Podcasts.app"; }
              { path = "/Applications/WezTerm.app"; }
              { path = "/Applications/Firefox.app"; }
              {
                path = "/System/Applications/System Preferences.app";
                section = "others";
              }
            ];
            description = "Dock entries configuration";
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
          default = "catppuccin";
          description = "Theme colorscheme";
        };

        variant = mkOption {
          type = types.str;
          default = "macchiato";
          description = "Theme variant";
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
            description = "Fallback font for nerd font glyphs";
          };
        };

        transparency = {
          opacity = mkOption {
            type = types.float;
            default = 0.8;
            description = "Transparency opacity level";
          };

          blur = mkOption {
            type = types.int;
            default = 20;
            description = "Background blur amount";
          };
        };
      };

      llm = {
        mcp = {
          servers = mkOption {
            type = types.attrsOf (
              types.submodule {
                options = {
                  command = mkOption {
                    type = types.str;
                    description = "MCP server command";
                  };
                  args = mkOption {
                    type = types.listOf types.str;
                    default = [ ];
                    description = "MCP server arguments";
                  };
                  env = mkOption {
                    type = types.attrsOf types.str;
                    default = { };
                    description = "Environment variables for MCP server";
                  };
                };
              }
            );
            default = { };
            description = "MCP servers configuration";
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

      vet = {
        additionalPackages = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Additional Vet packages";
        };
      };
    };
  };
}
