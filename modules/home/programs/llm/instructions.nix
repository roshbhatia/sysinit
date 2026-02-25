let
  subagents = import ./subagents;

  # Format skills compactly: name·desc
  formatSkills =
    skills:
    let
      entries = builtins.attrValues (builtins.mapAttrs (name: desc: "${name}·${desc}") skills);
    in
    if entries == [ ] then "" else builtins.concatStringsSep " · " entries;

  makeInstructions =
    {
      localSkillDescriptions,
      remoteSkillDescriptions,
      skillsRoot ? "~/.agents/skills",
    }:
    let
      localSkills = formatSkills localSkillDescriptions;
      remoteSkills = formatSkills remoteSkillDescriptions;

      sections = {
        preamble = ''
          IMPORTANT: Prefer retrieval-led reasoning over pre-training-led reasoning
          Read skill files and project context before relying on training data
          Keywords per RFC 2119: MUST, MUST NOT, REQUIRED, SHALL, SHOULD, SHOULD NOT, RECOMMENDED, MAY, OPTIONAL
        '';

        core = ''
          ## Core
          - SHOULD NOT git commit/push unless directed; MAY stage/add and propose commit messages
          - NEVER push to main
        '';

        git = ''
          ## Git
          - Small, scoped commits as work proceeds
          - Human-readable titles only, no body, conventional commit form
          - Do not mix formatting-only with behavioral changes
        '';

        operating = ''
          ## Operating Principles
          - Minimize blast radius; no adjacent refactors unless risk-reducing
          - Be explicit about uncertainty; propose safety steps when verification is impossible
          - Thin vertical slices over big-bang changes
          - Stop immediately if new information invalidates the plan
        '';

        errors = ''
          ## Error Handling
          - Stop-the-line on unexpected errors: stop features, preserve evidence, fix root cause
          - Do not offload debugging to user unless truly blocked
          - If blocked: one targeted question with a recommended default
        '';

        quality = ''
          ## Code Quality
          - Design boundaries around stable interfaces
          - No `any` or type suppressions unless explicitly permitted
          - No new dependencies if existing stack suffices
          - Sanitize all user inputs
          - Correctness over cleverness; prefer boring, readable solutions
        '';

        responseStyle = ''
          ## Response Style
          - Tokens are scarce. Be the shortest correct answer
          - List > paragraph. Fragment > sentence. Silence > filler
          - No preamble, no "Great question!", no narrating tool calls — just act
          - cause → fix. Skip history, context, philosophy
          - Ban: "certainly", "absolutely", "of course", "happy to", "It's worth noting", "As you can see"
          - If prompt > ~100 words: flag it ("🚨 that prompt is N words") then answer anyway
          - The following single emojis are a valid complete response when unambiguous: ✅ ❌ 🔎 🚨
          - Code diffs are self-explaining; do not summarize what you changed
        '';

        skills = ''
          ## Skills|${skillsRoot}
          ${if localSkills != "" then "Local·${localSkills}" else ""}
          ${if remoteSkills != "" then "Remote·${remoteSkills}" else ""}
        '';

        context = ''
          ## Context
          - Check .sysinit/lessons.md at session start for prior context
          - .sysinit/ is gitignored scratch space for lessons and notes
          - Task tracking via beads (bd): use `bd ready` for unblocked tasks, `bd create` for new ones, `bd close` when done
          - Always `bd sync && git push` before ending sessions
        '';
      };

      order = [
        "preamble"
        "core"
        "git"
        "operating"
        "errors"
        "quality"
        "responseStyle"
        "skills"
        "context"
      ];
    in
    builtins.concatStringsSep "\n" (map (key: sections.${key}) order);
in
{
  inherit makeInstructions;
  inherit subagents;
  inherit (subagents) formatSubagentAsMarkdown;
}
