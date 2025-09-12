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
        userName = mkOption {
          type = types.str;
          default = "User Name";
          description = "Git user name";
        };

        userEmail = mkOption {
          type = types.str;
          default = "user@example.com";
          description = "Git user email";
        };

        githubUser = mkOption {
          type = types.str;
          default = "username";
          description = "GitHub username";
        };

        credentialUsername = mkOption {
          type = types.str;
          default = "username";
          description = "Git credential username";
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

        personalGithubUser = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Personal GitHub username override";
        };

        workGithubUser = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Work GitHub username override";
        };
      };

      darwin = {
        tailscale = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable Tailscale";
          };
        };

        borders = {
          enable = mkOption {
            type = types.bool;
            default = false;
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

        transparency = {
          enable = mkOption {
            type = types.bool;
            default = true;
            description = "Enable transparency effects";
          };

          opacity = mkOption {
            type = types.float;
            default = 0.85;
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
        claude = {
          enabled = mkOption {
            type = types.bool;
            default = false;
            description = "Enable Claude Code integration";
          };

          yarnPackages = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = "Additional yarn packages for Claude";
          };

          uvPackages = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = "Additional uv packages for Claude";
          };
        };

        goose = {
          provider = mkOption {
            type = types.str;
            default = "github_copilot";
            description = "Goose provider configuration";
          };

          leadModel = mkOption {
            type = types.str;
            default = "claude-sonnet-4";
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
    };
  };

  defaultValues = {
    user = {
      username = "user";
      hostname = "nixos";
    };

    git = {
      userName = "User Name";
      userEmail = "user@example.com";
      githubUser = "username";
      credentialUsername = "username";
    };

    darwin = {
      tailscale = {
        enable = false;
      };
      borders = {
        enable = false;
      };
      homebrew = {
        additionalPackages = {
          taps = [ ];
          brews = [ ];
          casks = [ ];
        };
      };
    };

    yarn = {
      additionalPackages = [ ];
    };

    theme = {
      colorscheme = "catppuccin";
      variant = "macchiato";
      transparency = {
        enable = true;
        opacity = 0.85;
        blur = 80;
      };
    };

    wezterm = {
      shell = "zsh";
    };

    llm = {
      claude = {
        enabled = false;
        yarnPackages = [ ];
        uvPackages = [ ];
      };
      goose = {
        provider = "openrouter";
        leadModel = "qwen/qwen3-coder:free";
        model = "google/gemini-2.0-flash-exp:free";
      };
    };

    uvx = {
      additionalPackages = [ ];
    };

    pipx = {
      additionalPackages = [ ];
    };

    krew = {
      additionalPackages = [ ];
    };

    npm = {
      additionalPackages = [ ];
    };

    gh = {
      additionalPackages = [ ];
    };

    go = {
      additionalPackages = [ ];
    };

    cargo = {
      additionalPackages = [ ];
    };

    nix = {
      additionalPackages = [ ];
    };
  };
}
