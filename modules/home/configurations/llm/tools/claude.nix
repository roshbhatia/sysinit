{ lib, values, ... }:
let
  claudeConfig = import ../config/claude.nix;
  themes = import ../../../../lib/theme { inherit lib; };

  claudeEnabled = values.llm.claude.enabled or false;

  themeColors = themes.getThemePalette values.theme.colorscheme values.theme.variant;

  claudePowerlineTheme = {
    directory = {
      bg = themeColors.blue;
      fg = themeColors.base;
    };
    git = {
      bg = themeColors.green;
      fg = themeColors.base;
    };
    model = {
      bg = themeColors.mauve;
      fg = themeColors.base;
    };
    session = {
      bg = themeColors.pink;
      fg = themeColors.base;
    };
    block = {
      bg = themeColors.surface1;
      fg = themeColors.text;
    };
    today = {
      bg = themeColors.surface0;
      fg = themeColors.subtext1;
    };
    context = {
      bg = themeColors.surface2;
      fg = themeColors.text;
    };
    tmux = {
      bg = themeColors.green;
      fg = themeColors.base;
    };
    metrics = {
      bg = themeColors.overlay1;
      fg = themeColors.text;
    };
    version = {
      bg = themeColors.overlay0;
      fg = themeColors.subtext1;
    };
  };
in
lib.mkIf claudeEnabled {
  home.file = {
    "claude/settings.json" = {
      text = builtins.toJSON {
        statusLine = {
          type = "command";
          command = "npx -y @owloops/claude-powerline@latest --theme=custom --style=powerline";
          padding = 0;
        };

        theme = claudeConfig.theme;

        features = {
          codeCompletion = claudeConfig.codeCompletion;
          contextAwareness = claudeConfig.contextAwareness;
          memoryManagement = claudeConfig.memoryManagement;
        };

        shareAnalytics = claudeConfig.shareAnalytics;
        localMode = claudeConfig.localMode;

        editor = {
          fontSize = 14;
          fontFamily = "JetBrains Mono";
          lineNumbers = true;
          wordWrap = true;
        };
      };
      force = true;
    };

    ".config/claude-powerline/config.json" = {
      text = builtins.toJSON {
        theme = "custom";
        colors = {
          custom = claudePowerlineTheme;
        };
        display = {
          lines = [
            {
              segments = {
                directory = {
                  enabled = true;
                  showBasename = false;
                };
                git = {
                  enabled = true;
                  showSha = false;
                  showWorkingTree = true;
                  showOperation = true;
                  showTag = false;
                  showTimeSinceCommit = false;
                  showStashCount = false;
                  showUpstream = false;
                  showRepoName = false;
                };
                model = {
                  enabled = true;
                };
                session = {
                  enabled = true;
                  type = "tokens";
                };
                block = {
                  enabled = false;
                };
                today = {
                  enabled = false;
                };
                context = {
                  enabled = false;
                };
                tmux = {
                  enabled = false;
                };
                metrics = {
                  enabled = false;
                };
                version = {
                  enabled = true;
                };
              };
            }
          ];
        };
      };
      force = true;
    };
  };
}
