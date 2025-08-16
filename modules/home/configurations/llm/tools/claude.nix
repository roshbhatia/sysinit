{ lib, values, ... }:
let
  claudeConfig = import ../config/claude.nix;
  agents = import ../shared/agents.nix;
  themes = import ../../../../lib/theme { inherit lib; };

  # Only support Claude Code - no API configuration needed
  claudeEnabled = values.llm.claude.enabled or false;

  # Theme integration for claude-powerline
  themeColors = themes.getThemePalette values.theme.colorscheme values.theme.variant;

  # Map our theme colors to claude-powerline custom theme format
  claudePowerlineTheme = {
    directory = { bg = themeColors.blue; fg = themeColors.base; };
    git = { bg = themeColors.green; fg = themeColors.base; };
    model = { bg = themeColors.mauve; fg = themeColors.base; };
    session = { bg = themeColors.pink; fg = themeColors.base; };
    block = { bg = themeColors.surface1; fg = themeColors.text; };
    today = { bg = themeColors.surface0; fg = themeColors.subtext1; };
    context = { bg = themeColors.surface2; fg = themeColors.text; };
    tmux = { bg = themeColors.green; fg = themeColors.base; };
    metrics = { bg = themeColors.overlay1; fg = themeColors.text; };
    version = { bg = themeColors.overlay0; fg = themeColors.subtext1; };
  };
in
lib.mkIf claudeEnabled {
  # All home files for Claude configuration
  home.file = {
    # Claude Code settings.json
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

        shortcuts = {
          newChat = "Cmd+N";
          clearContext = "Cmd+K";
          exportChat = "Cmd+E";
          toggleSidebar = "Cmd+B";
        };
      };
      force = true;
    };

    # Claude-powerline custom theme configuration
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
                directory = { enabled = true; showBasename = false; };
                git = {
                  enabled = true;
                  showSha = true;
                  showWorkingTree = false;
                  showOperation = false;
                  showTag = false;
                  showTimeSinceCommit = false;
                  showStashCount = false;
                  showUpstream = true;
                  showRepoName = false;
                };
                model = { enabled = true; };
                session = { enabled = true; type = "tokens"; };
                block = { enabled = true; type = "cost"; burnType = "cost"; };
                today = { enabled = true; type = "cost"; };
                context = { enabled = true; };
                tmux = { enabled = true; };
                metrics = {
                  enabled = true;
                  showResponseTime = true;
                  showLastResponseTime = false;
                  showDuration = true;
                  showMessageCount = true;
                };
                version = { enabled = true; };
              };
            }
          ];
        };
      };
      force = true;
    };
  } // builtins.listToAttrs (
    # User-level subagents
    map (agent: {
      name = ".claude/agents/${agent.name}.md";
      value = {
        text = ''
          ---
          name: ${agent.name}
          description: ${agent.description}
          ---

          ${agent.prompt}
        '';
      };
    }) agents
  );
}

