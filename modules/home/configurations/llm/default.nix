{
  lib,
  pkgs,
  ...
}:
let
  skills = import ./skills.nix { inherit pkgs; };

  # Claude Code standard path - most tools can read from here
  claudeSkillFiles = lib.mapAttrs' (
    name: path: lib.nameValuePair ".claude/skills/${name}/SKILL.md" { source = path; }
  ) skills.allSkills;

  # OpenCode native path (also reads from .claude/skills but this is primary)
  opencodeSkillFiles = lib.mapAttrs' (
    name: path: lib.nameValuePair ".config/opencode/skills/${name}/SKILL.md" { source = path; }
  ) skills.allSkills;

  skillFiles = claudeSkillFiles // opencodeSkillFiles;
in
{
  imports = [
    ./config/amp.nix
    ./config/beads.nix
    ./config/claude.nix
    ./config/codex.nix
    ./config/copilot-cli.nix
    ./config/cursor.nix
    ./config/gemini.nix
    ./config/goose.nix
    ./config/opencode.nix
    ./cupcake
  ];

  home.file = skillFiles;
}
