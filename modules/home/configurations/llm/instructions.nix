let
  subagents = import ./subagents;

  makeInstructions =
    {
      localSkillDescriptions,
      remoteSkillDescriptions,
    }:
    let
      skillsList =
        skills:
        builtins.concatStringsSep "|" (
          builtins.attrValues (builtins.mapAttrs (name: desc: "${name}:${desc}") skills)
        );

      sections = [
        "IMPORTANT: Prefer retrieval-led reasoning over pre-training-led reasoning"
        "Read skill files and project context before relying on training data"
        "Keywords per RFC 2119: MUST, MUST NOT, REQUIRED, SHALL, SHOULD, SHOULD NOT, RECOMMENDED, MAY, OPTIONAL"
        "## Core"
        "- MUST be concise and clear in communication"
        "- MUST understand project scope and tech stack before execution"
        "- MUST fix errors proactively and clarify stack assumptions"
        "- MUST read context files and documentation first"
        "- MUST start code with path/filename and include purpose comments"
        "- MUST apply modularity, DRY, performance, security principles"
        "- MUST finish one file before starting another"
        "- MUST use astgrep over internal tools for file exploration/editing"
        "- NEVER create ad-hoc documentation; MAY create human-standard documentation"
        "- NEVER use emojis in code"
        "- SHOULD NOT git commit/push unless directed; MAY stage/add and propose commit messages"
        "- NEVER push to main"
        "## Git"
        "- Small, scoped commits as work proceeds"
        "- Human-readable titles only, no body, conventional commit form"
        "- Do not mix formatting-only with behavioral changes"
        "## Operating Principles"
        "- Minimize blast radius; no adjacent refactors unless risk-reducing"
        "- Be explicit about uncertainty; propose safety steps when verification is impossible"
        "- Use subagents for parallel exploration, merge outputs before coding"
        "- Thin vertical slices over big-bang changes"
        "- Stop immediately if new information invalidates the plan"
        "## Error Handling"
        "- Stop-the-line on unexpected errors: stop features, preserve evidence, fix root cause"
        "- Do not offload debugging to user unless truly blocked"
        "- If blocked: one targeted question with a recommended default"
        "## Code Quality"
        "- Design boundaries around stable interfaces"
        "- No `any` or type suppressions unless explicitly permitted"
        "- No new dependencies if existing stack suffices"
        "- Sanitize all user inputs"
        "- Fix N+1 patterns and unbounded loops; no premature optimization"
        "- Correctness over cleverness; prefer boring, readable solutions"
        "## Skills Index|root: ~/.agents/skills"
        "Local (repo-specific):|${skillsList localSkillDescriptions}"
        "Remote (obra/superpowers):|${skillsList remoteSkillDescriptions}"
        "## Context"
        "- Check .sysinit/lessons.md at session start for prior context"
        "- .sysinit/ is gitignored scratch space for PRDs, lessons, and notes"
      ];
    in
    builtins.concatStringsSep "\n" sections;
in
{
  inherit makeInstructions;
  inherit subagents;
  inherit (subagents) formatSubagentAsMarkdown;
}
