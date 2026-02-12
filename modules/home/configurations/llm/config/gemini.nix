{
  lib,
  pkgs,
  values,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  mcpServers = import ../mcp.nix { inherit lib values; };
  skillsLib = import ../skills.nix { inherit pkgs; };

  defaultInstructions = llmLib.instructions.makeInstructions {
    inherit (skillsLib) localSkillDescriptions remoteSkillDescriptions;
    skillsRoot = "~/.claude/skills";
  };

  geminiSettingsToml = ''
    # MCP Servers
    [mcpServers]
    ${llmLib.mcp.formatForGemini mcpServers.servers}
  '';

in
{
  xdg.configFile = {
    "gemini/settings.toml" = {
      text = geminiSettingsToml;
      force = true;
    };
    "gemini/GEMINI.md" = {
      text = defaultInstructions;
      force = true;
    };
  };

  home.packages = with pkgs; [
    gemini-cli
  ];
}
