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
    skillsRoot = "~/.claude/skills";
  };
in
{
  programs.codex = {
    enable = true;
    enableMcpIntegration = true;
    custom-instructions = defaultInstructions;
  };
}
