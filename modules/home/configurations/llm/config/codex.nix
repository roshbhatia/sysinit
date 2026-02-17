{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  mcpServers = import ../mcp.nix {
    inherit lib;
    additionalServers = config.sysinit.llm.mcp.additionalServers;
  };
  skillsLib = import ../skills.nix { inherit pkgs; };

  defaultInstructions = llmLib.instructions.makeInstructions {
    inherit (skillsLib) localSkillDescriptions;
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
