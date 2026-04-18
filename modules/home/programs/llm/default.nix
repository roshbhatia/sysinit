{
  lib,
  pkgs,
  config,
  ...
}:
let
  skills = import ./skills.nix { inherit pkgs; };

  # Claude Code standard path - most tools can read from here
  claudeSkillFiles = lib.mapAttrs' (
    name: path: lib.nameValuePair ".claude/skills/${name}/SKILL.md" { source = path; }
  ) skills.allSkills;

  skillFiles = claudeSkillFiles;
in
{
  imports = [
    ./config/aider.nix
    ./config/amp.nix
    ./config/claude.nix
    ./config/codex.nix
    ./config/copilot-cli.nix
    ./config/crush.nix
    ./config/cursor.nix
    ./config/gemini.nix
    ./config/goose.nix
    ./config/mcp-servers.nix
    ./config/opencode.nix
    ./config/pi.nix
  ];

  home.file = skillFiles;

  programs.mcp = {
    enable = true;
    servers = config.sysinit.llm.mcp.additionalServers;
  };
}
