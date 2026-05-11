{
  lib,
  pkgs,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  skillsLib = import ../skills.nix { inherit pkgs; };

  defaultInstructions = llmLib.instructions.makeInstructions {
    inherit (skillsLib) localSkillDescriptions;
    openspecVersion = pkgs.openspec.version;
    skillsRoot = "~/.claude/skills";
  };
in
{
  programs.codex = {
    enable = true;
    enableMcpIntegration = true;
    context = defaultInstructions;
  };
}
