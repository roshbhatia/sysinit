{ lib }:

with lib;
let
  constants = import ../theme/core/constants.nix;
in
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
            default = "MonaspiceKr Nerd Font Mono";
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

      wezterm = {
        shell = mkOption {
          type = types.str;
          default = "zsh";
          description = "Default shell for wezterm";
        };
      };

      llm = {
        # Global LLM configuration
        agentsMd = {
          enabled = mkOption {
            type = types.bool;
            default = true;
            description = "Enable AGENTS.md integration across all LLM configurations";
          };

          autoUpdate = mkOption {
            type = types.bool;
            default = true;
            description = "Automatically update AGENTS.md when configuration changes";
          };
        };

        # Execution environment configuration
        execution = {
          nixShell = {
            enabled = mkOption {
              type = types.bool;
              default = true;
              description = "Enable nix-shell integration for dynamic dependency management";
            };

            autoDeps = mkOption {
              type = types.bool;
              default = true;
              description = "Automatically download dependencies via nix-shell when needed";
            };

            sandbox = mkOption {
              type = types.bool;
              default = true;
              description = "Use nix-shell sandboxing for isolation";
            };
          };

          terminal = {
            wezterm = {
              enabled = mkOption {
                type = types.bool;
                default = true;
                description = "Enable wezterm session spawning for visibility";
              };

              newWindow = mkOption {
                type = types.bool;
                default = true;
                description = "Spawn commands in new wezterm windows";
              };

              monitor = mkOption {
                type = types.bool;
                default = true;
                description = "Monitor command execution in terminal";
              };
            };
          };

          isolation = {
            enabled = mkOption {
              type = types.bool;
              default = true;
              description = "Enable execution isolation for security";
            };

            monitoring = mkOption {
              type = types.bool;
              default = true;
              description = "Monitor resource usage during execution";
            };

            timeout = mkOption {
              type = types.int;
              default = 300;
              description = "Default execution timeout in seconds";
            };
          };
        };

        # Claude Desktop configuration
        claude = {
          enabled = mkOption {
            type = types.bool;
            default = true;
            description = "Enable Claude Desktop configuration";
          };

          mcp = {
            aws = {
              region = mkOption {
                type = types.str;
                default = "us-east-1";
                description = "Default AWS region for MCP servers";
              };

              enabled = mkOption {
                type = types.bool;
                default = true;
                description = "Enable AWS MCP servers";
              };
            };

            additionalServers = mkOption {
              type = types.attrsOf (types.attrsOf types.anything);
              default = { };
              description = "Additional MCP servers for Claude";
            };
          };
        };

        # Goose AI assistant configuration
        goose = {
          enabled = mkOption {
            type = types.bool;
            default = true;
            description = "Enable Goose AI assistant configuration";
          };

          provider = mkOption {
            type = types.str;
            default = constants.llmDefaults.goose.provider;
            description = "Goose provider configuration";
          };

          leadModel = mkOption {
            type = types.nullOr types.str;
            default = constants.llmDefaults.goose.leadModel;
            description = "Goose lead model configuration";
          };

          model = mkOption {
            type = types.str;
            default = constants.llmDefaults.goose.model;
            description = "Goose model configuration";
          };

          alphaFeatures = mkOption {
            type = types.bool;
            default = constants.llmDefaults.goose.alphaFeatures;
            description = "Enable Goose alpha features";
          };

          mode = mkOption {
            type = types.str;
            default = constants.llmDefaults.goose.mode;
            description = "Goose interaction mode";
          };
        };

        # Opencode IDE configuration
        opencode = {
          enabled = mkOption {
            type = types.bool;
            default = true;
            description = "Enable Opencode IDE configuration";
          };

          theme = mkOption {
            type = types.str;
            default = constants.llmDefaults.opencode.theme;
            description = "Opencode theme configuration";
          };

          autoupdate = mkOption {
            type = types.bool;
            default = constants.llmDefaults.opencode.autoupdate;
            description = "Enable Opencode auto-update";
          };

          share = mkOption {
            type = types.str;
            default = constants.llmDefaults.opencode.share;
            description = "Opencode sharing configuration";
          };
        };

        # Cursor CLI configuration
        cursor = {
          enabled = mkOption {
            type = types.bool;
            default = true;
            description = "Enable Cursor CLI configuration";
          };

          vimMode = mkOption {
            type = types.bool;
            default = constants.llmDefaults.cursor.vimMode;
            description = "Enable Vim mode in Cursor";
          };

          permissions = {
            shell = {
              allowed = mkOption {
                type = types.listOf types.str;
                default = constants.llmDefaults.cursor.permissions.shell.allowed;
                description = "Allowed shell commands for Cursor";
              };
            };

            kubectl = {
              allowed = mkOption {
                type = types.listOf types.str;
                default = constants.llmDefaults.cursor.permissions.kubectl.allowed;
                description = "Allowed kubectl commands for Cursor";
              };
            };
          };
        };

        # MCP servers configuration
        mcp = {
          servers = mkOption {
            type = types.attrsOf (types.attrsOf types.anything);
            default = { };
            description = "Additional MCP servers configuration";
          };

          additionalServers = mkOption {
            type = types.listOf (types.attrsOf types.anything);
            default = [ ];
            description = "Additional MCP servers in list format";
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
