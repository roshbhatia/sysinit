{
  lib,
  pkgs,
  ...
}:
let
  skills = import ./skills.nix { inherit lib pkgs; };

  globalSkillFiles = lib.mapAttrs' (
    name: path: lib.nameValuePair ".agents/skills/${name}/SKILL.md" { source = path; }
  ) skills.allSkills;
in
{
  imports = [
    ./config/amp.nix
    ./config/claude.nix
    ./config/crush.nix
    ./config/cursor.nix
    ./config/goose.nix
    ./config/opencode.nix
    ./config/copilot-cli.nix
    ./cupcake
    ./tools.nix
  ];

  home.file = globalSkillFiles;
}
