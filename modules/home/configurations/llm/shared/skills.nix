{
  pkgs,
  ...
}:

let
  skillsRepo = pkgs.fetchgit {
    url = "https://github.com/obra/superpowers.git";
    rev = "main";
    sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  allSkills = [
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

  skillContent =
    skillName:
    pkgs.writeText "${skillName}-skill.md" (
      builtins.readFile "${skillsRepo}/skills/${skillName}/${skillName}.md"
    );

in
{
  allSkills = builtins.listToAttrs (
    map (skillName: {
      name = skillName;
      value = skillContent skillName;
    }) allSkills
  );

  agentsMd = ''
    Keywords: MUST, MUST NOT, REQUIRED, SHALL, SHALL NOT, SHOULD, SHOULD NOT, RECOMMENDED, MAY, OPTIONAL. (RFC 2119)

    MUST be concise and clear in communication.
    MUST understand project scope and tech stack before execution.
    MUST fix errors proactively and clarify stack assumptions.
    MUST read context files and documentation.
    MUST start code with path/filename and include purpose comments.
    MUST apply modularity, DRY, performance, security principles.
    MUST finish one file before starting another.
    MUST use TODO for incomplete work and confirm before proceeding.
    MUST deliver refined, complete files; return only modified symbols.
    NEVER create ad-hoc documentaiton. You MAY create applicable documentation, but only that which a human would write.
    MUST use serena_get_symbols_overview first when exploring files.
    MUST use serena and astgrep over internal tools exploring files and editing files.
    MUST reference your memory via serena.
    NEVER use emojis in code.
  '';
}
