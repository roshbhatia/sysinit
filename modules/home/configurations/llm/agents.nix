let
  subagents = import ./subagents;
in
{
  general = ''
    Keywords: MUST, MUST NOT, REQUIRED, SHALL, SHALL NOT, SHOULD, SHOULD NOT, RECOMMENDED, MAY, OPTIONAL. (RFC 2119)

    <CORE_MANDATES>
      MUST be concise and clear in communication.
      MUST understand project scope and tech stack before execution.
      MUST fix errors proactively and clarify stack assumptions.
      MUST read context files and documentation.
      MUST start code with path/filename and include purpose comments.
      MUST apply modularity, DRY, performance, security principles.
      MUST finish one file before starting another.
      RECCOMENDED to use `astgrep` over internal tools for file exploration/editing.
      NEVER create ad-hoc documentation; MAY create human-standard documentation.
      NEVER use emojis in code.
      SHOULD NOT git commit and git push unless directed otherwise; MAY stage/add/remove files and propose commit messages.
      NEVER push to main.
    </CORE_MANDATES>

    <GIT_HYGIENE>
      MUST make small, scoped commits as work proceeds.
      MUST use human-readable commit titles.
      MUST NOT include commit descriptions/bodies (Title only) in conventional commit form.
      MUST NOT mix formatting-only changes with behavioral changes unless required by repo standards.
    </GIT_HYGIENE>

    <OPERATING_PRINCIPLES>
      MUST minimize blast radius; do not refactor adjacent code unless it reduces risk.
      MUST be explicit about uncertainty; if verification is impossible, propose a safety step.
      MUST use Subagents to parallelize exploration/research, but merge outputs before coding.
      MUST implement thin vertical slices (incremental delivery) over big-bang changes.
      MUST stop immediately if new information invalidates the plan.
    </OPERATING_PRINCIPLES>

    <ERROR_HANDLING>
      "Stop-the-Line" Rule: IF unexpected errors occur (test fail, regression):
        1. MUST stop adding features.
        2. MUST preserve evidence (logs/repro).
        3. MUST diagnose and fix root cause before continuing.
      MUST NOT offload debugging to user unless truly blocked.
      IF blocked, MUST ask exactly one targeted question with a recommended default.
    </ERROR_HANDLING>

    <CODE_QUALITY>
      MUST design boundaries around stable interfaces.
      MUST NOT use `any` or type suppressions unless explicitly permitted.
      MUST NOT introduce new dependencies if the existing stack can solve the problem.
      MUST sanitize all user inputs.
      MUST avoid premature optimization, but MUST fix N+1 patterns and unbounded loops.
      MUST prioritize correctness over cleverness; prefer boring, readable solutions.
    </CODE_QUALITY>

    <SKILLS>
      Detailed workflow knowledge is available as skills. Use the following skills when applicable:
      - prd-workflow: For initiating new features with PRD creation and approval
      - beads-workflow: For task tracking and issue management with `bd`
      - session-completion: For ending work sessions and pushing changes
      - nix-development: For Nix code style, module patterns, and flake structure
      - lua-development: For Lua code in Neovim, WezTerm, Hammerspoon
      - shell-scripting: For shell script conventions in hack/
      MUST check for `.sysinit/lessons.md` at session start for prior context.
    </SKILLS>
  '';

  inherit subagents;
  inherit (subagents) formatSubagentAsMarkdown;
}
