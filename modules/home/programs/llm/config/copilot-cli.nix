{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };

  copilotConfig = builtins.toJSON {
    banner = "never";
    renderMarkdown = true;
    screenReader = false;
    theme = "auto";
    trusted_folders = [ ];
    autoUpdate = false;
  };

  copilotMcpConfig = builtins.toJSON {
    mcpServers = llmLib.mcp.formatForCopilot kit.mcpServers.servers;
  };
in
{
  home.file = {
    ".copilot/config.json" = {
      text = copilotConfig;
      force = true;
    };
    ".copilot/mcp-config.json" = {
      text = copilotMcpConfig;
      force = true;
    };

    # Copilot reads user-level instructions here. The app bundle lists
    # `$HOME/.copilot/copilot-instructions.md` alongside
    # `$HOME/.copilot/instructions/**/*.instructions.md`, and `--help` carries
    # `--no-custom-instructions` to turn both off.
    #
    # An earlier audit concluded copilot had no global instruction path. That
    # was wrong: it scanned the wrapper binary rather than the JS bundle under
    # lib/, where every one of these strings lives.
    ".copilot/copilot-instructions.md" = {
      text = kit.mkInstructionsWithStyle {
        harness = "copilot";
        skillsRoot = "~/.copilot/skills";
      };
      force = true;
    };
  };
}
