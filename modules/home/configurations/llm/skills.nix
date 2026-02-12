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

  remoteSkillDescriptions = {
    brainstorming = "creative ideation and exploration";
    dispatching-parallel-agents = "coordinating multiple agent workers";
    executing-plans = "structured plan execution";
    finishing-a-development-branch = "branch cleanup and merge prep";
    receiving-code-review = "processing and applying review feedback";
    requesting-code-review = "preparing code for review";
    subagent-driven-development = "delegating work to sub-agents";
    systematic-debugging = "structured debugging methodology";
    test-driven-development = "TDD workflow";
    using-git-worktrees = "parallel branch work with worktrees";
    using-superpowers = "leveraging the superpowers skill system";
    verification-before-completion = "pre-completion verification checks";
    writing-plans = "creating structured plans";
    writing-skills = "authoring new skills";
  };

  localSkillContent = import ./skills;

  remoteSkills = builtins.listToAttrs (
    map (skillName: {
      name = skillName;
      value = "${skillsRepo}/skills/${skillName}/SKILL.md";
    }) remoteSkillNames
  );

  localSkills = builtins.mapAttrs (
    name: skill: pkgs.writeText "skill-${name}-SKILL.md" skill.content
  ) localSkillContent;

  localSkillDescriptions = builtins.mapAttrs (_name: skill: skill.description) localSkillContent;

  allSkills = remoteSkills // localSkills;

  # Generate home.file entries to install skills to a directory
  # Returns an attrset suitable for home.file or xdg.configFile
  installSkillsTo = _basePath: builtins.mapAttrs (_name: path: { source = path; }) allSkills;
in
{
  inherit
    allSkills
    localSkillDescriptions
    remoteSkillDescriptions
    installSkillsTo
    ;
}
