{
  lib,
  pkgs,
  ...
}:
let
  skills = import ./skills.nix { inherit lib pkgs; };

  # Install skills to both ~/.agents/skills and ~/.claude/skills
  agentsSkillFiles = lib.mapAttrs' (
    name: path: lib.nameValuePair ".agents/skills/${name}/SKILL.md" { source = path; }
  ) skills.allSkills;

  claudeSkillFiles = lib.mapAttrs' (
    name: path: lib.nameValuePair ".claude/skills/${name}/SKILL.md" { source = path; }
  ) skills.allSkills;

  skillFiles = agentsSkillFiles // claudeSkillFiles;
in
{
  imports = [
    ./config/amp.nix
    ./config/beads.nix
    ./config/claude.nix
    ./config/copilot-cli.nix
    ./config/crush.nix
    ./config/cursor.nix
    ./config/goose.nix
    ./config/opencode.nix
    ./cupcake
  ];

  home.file = skillFiles;
}
