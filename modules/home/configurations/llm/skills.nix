{
  pkgs,
  ...
}:

let
  skillsRepo = pkgs.fetchFromGitHub {
    owner = "obra";
    repo = "superpowers";
    rev = "main";
    sha256 = "sha256-0/biMK5A9DwXI/UeouBX2aopkUslzJPiNi+eZFkkzXI=";
  };

  remoteSkillNames = [
    "brainstorming"
    "dispatching-parallel-agents"
    "executing-plans"
    "finishing-a-development-branch"
    "receiving-code-review"
    "requesting-code-review"
    "subagent-driven-development"
    "systematic-debugging"
    "test-driven-development"
    "using-git-worktrees"
    "using-superpowers"
    "verification-before-completion"
    "writing-plans"
    "writing-skills"
  ];

  localSkillContent = import ./skills;

  remoteSkills = builtins.listToAttrs (
    map (skillName: {
      name = skillName;
      value = "${skillsRepo}/skills/${skillName}/SKILL.md";
    }) remoteSkillNames
  );

  localSkills = builtins.mapAttrs (
    name: content: pkgs.writeText "skill-${name}-SKILL.md" content
  ) localSkillContent;

in
{
  allSkills = remoteSkills // localSkills;
}
