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

  codexConfigToml = ''
    # Codex CLI configuration

    # MCP Servers
    ${llmLib.mcp.formatForCodex mcpServers.servers}
  '';

in
{
  xdg.configFile = {
    "codex/config.toml" = {
      text = codexConfigToml;
      force = true;
    };
    "codex/AGENTS.md" = {
      text = defaultInstructions;
      force = true;
    };
  };

  home.packages = with pkgs; [
    codex
  ];
}
