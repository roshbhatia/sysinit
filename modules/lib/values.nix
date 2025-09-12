{ lib }:

with lib;

let
  themes = import ./theme { inherit lib; };
in

rec {
  # Validation functions (from validation.nix)
  validateTheme =
    colorscheme: variant:
    let
      availableColorschemes = attrNames themes.themes;
      availableVariants =
        if hasAttr colorscheme themes.themes then themes.themes.${colorscheme}.meta.variants else [ ];
    in
    [
      {
        assertion = hasAttr colorscheme themes.themes;
        message = ''
          Invalid colorscheme: '${colorscheme}'
          Available colorschemes: ${concatStringsSep ", " availableColorschemes}
        '';
      }
      {
        assertion = elem variant availableVariants;
        message = ''
          Invalid variant '${variant}' for colorscheme '${colorscheme}'
          Available variants: ${concatStringsSep ", " availableVariants}
        '';
      }
    ];

  validateEmail = email: {
    assertion = builtins.match ".*@.*\\..*" email != null;
    message = "Invalid email address: '${email}'";
  };

  validateHostname = hostname: {
    assertion = builtins.match "[a-zA-Z0-9][a-zA-Z0-9\\-]{0,61}[a-zA-Z0-9]?" hostname != null;
    message = "Invalid hostname: '${hostname}'. Must be valid DNS hostname.";
  };

  validatePackageList =
    packages: packageType:
    map (pkg: {
      assertion = isString pkg && pkg != "";
      message = "Invalid ${packageType} package: '${toString pkg}' must be a non-empty string";
    }) packages;

  validatePath = path: {
    assertion = isString path && path != "";
    message = "Path must be a non-empty string: '${toString path}'";
  };

  validateUserConfig = values: [
    {
      assertion = values.user.username != "";
      message = "user.username cannot be empty";
    }
    (validateHostname values.user.hostname)
  ];

  validateGitConfig =
    values:
    [
      (validateEmail values.git.userEmail)
      {
        assertion = values.git.userName != "";
        message = "git.userName cannot be empty";
      }
      {
        assertion = values.git.githubUser != "";
        message = "git.githubUser cannot be empty";
      }
    ]
    ++ optionals (values.git ? personalEmail && values.git.personalEmail != null) [
      (validateEmail values.git.personalEmail)
    ]
    ++ optionals (values.git ? workEmail && values.git.workEmail != null) [
      (validateEmail values.git.workEmail)
    ];

  validateThemeConfig =
    values:
    validateTheme values.theme.colorscheme values.theme.variant
    ++ [
      {
        assertion = values.theme.transparency.opacity >= 0.0 && values.theme.transparency.opacity <= 1.0;
        message = "theme.transparency.opacity must be between 0.0 and 1.0, got: ${toString values.theme.transparency.opacity}";
      }
      {
        assertion = values.theme.transparency.blur >= 0 && values.theme.transparency.blur <= 100;
        message = "theme.transparency.blur must be between 0 and 100, got: ${toString values.theme.transparency.blur}";
      }
    ];

  validateYarnPackages = values: validatePackageList values.yarn.additionalPackages "yarn";

  validateAllConfigs =
    values:
    flatten [
      (validateUserConfig values)
      (validateGitConfig values)
      (validateThemeConfig values)
      (validateYarnPackages values)
    ];

  # Integration functions (from validation-integration.nix)
  generateValidationWarnings = values: [
    (mkIf (
      values.theme.colorscheme == "solarized" && values.theme.variant == "light"
    ) "Light theme variants may have reduced readability in some applications")

    (mkIf (length values.yarn.additionalPackages > 10)
      "Large number of yarn packages (${toString (length values.yarn.additionalPackages)}) may slow system startup"
    )

    (mkIf (
      values.theme.transparency.opacity < 0.5
    ) "Very low opacity (${toString values.theme.transparency.opacity}) may affect readability")
  ];

  # Values type definition
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
}
