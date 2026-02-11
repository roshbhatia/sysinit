let
  subagents = import ./subagents;

  compressSkillDescriptions =
    skills:
    builtins.concatStringsSep "|" (
      builtins.attrValues (builtins.mapAttrs (name: desc: "${name}:${desc}") skills)
    );

  localSkillDescriptions = {
    beads-workflow = "task tracking, issue management, multi-step work with bd";
    lua-development = "Lua for Neovim, WezTerm, Hammerspoon, Sketchybar";
    nix-development = "Nix modules, flake structure, nixfmt, build/test";
    prd-workflow = "new features: PRD creation, approval, implementation";
    session-completion = "ending sessions: commit, push, hand off context";
    shell-scripting = "shell scripts in hack/, Taskfile, shfmt";
  };

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
in
{
  general = ''
    IMPORTANT: Prefer retrieval-led reasoning over pre-training-led reasoning.
    Read skill files and project context before relying on training data.

    Keywords per RFC 2119: MUST, MUST NOT, REQUIRED, SHALL, SHOULD, SHOULD NOT, RECOMMENDED, MAY, OPTIONAL.

    ## Core

    - MUST be concise and clear in communication
    - MUST understand project scope and tech stack before execution
    - MUST fix errors proactively and clarify stack assumptions
    - MUST read context files and documentation first
    - MUST start code with path/filename and include purpose comments
    - MUST apply modularity, DRY, performance, security principles
    - MUST finish one file before starting another
    - MUST use astgrep over internal tools for file exploration/editing
    - NEVER create ad-hoc documentation; MAY create human-standard documentation
    - NEVER use emojis in code
    - SHOULD NOT git commit/push unless directed; MAY stage/add and propose commit messages
    - NEVER push to main
    - SHOULD NOT put comments on the top of files

    ## Git

    - Small, scoped commits as work proceeds
    - Human-readable titles only, no body, conventional commit form
    - Do not mix formatting-only with behavioral changes

    ## Operating Principles

    - Minimize blast radius; no adjacent refactors unless risk-reducing
    - Be explicit about uncertainty; propose safety steps when verification is impossible
    - Use subagents for parallel exploration, merge outputs before coding
    - Thin vertical slices over big-bang changes
    - Stop immediately if new information invalidates the plan

    ## Error Handling

    - Stop-the-line on unexpected errors: stop features, preserve evidence, fix root cause
    - Do not offload debugging to user unless truly blocked
    - If blocked: one targeted question with a recommended default

    ## Code Quality

    - Design boundaries around stable interfaces
    - No `any` or type suppressions unless explicitly permitted
    - No new dependencies if existing stack suffices
    - Sanitize all user inputs
    - Fix N+1 patterns and unbounded loops; no premature optimization
    - Correctness over cleverness; prefer boring, readable solutions

    ## Skills Index (root: ~/.agents/skills)

    Read the SKILL.md file for full workflow details before acting on a skill.

    Local (repo-specific):|${compressSkillDescriptions localSkillDescriptions}
    Remote (obra/superpowers):|${compressSkillDescriptions remoteSkillDescriptions}

    ## Context

    - Check .sysinit/lessons.md at session start for prior context
    - .sysinit/ is gitignored scratch space for PRDs, lessons, and notes
  '';

  inherit subagents;
  inherit (subagents) formatSubagentAsMarkdown;
}
