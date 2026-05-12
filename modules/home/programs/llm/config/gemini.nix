{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };

  geminiSettingsToml = ''
    # MCP Servers
    [mcpServers]
    ${llmLib.mcp.formatForGemini kit.mcpServers.servers}
  '';
in
{
  xdg.configFile = {
    "gemini/settings.toml" = {
      text = geminiSettingsToml;
      force = true;
    };
    "gemini/GEMINI.md" = {
      text = kit.mkInstructions "~/.claude/skills";
      force = true;
    };
  };

  home.packages = [ pkgs.gemini-cli ];
}
