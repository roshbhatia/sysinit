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

  skillFiles = claudeSkillFiles;
in
{
  imports = [
    ./config/amp.nix
    ./config/beads.nix
    ./config/claude.nix
    ./config/codex.nix
    ./config/copilot-cli.nix
    ./config/crush.nix
    ./config/cursor.nix
    ./config/gemini.nix
    ./config/goose.nix
    ./config/opencode.nix
  ];

  home.file = skillFiles;
}
