# Instruction-writing principles for this file. The rendered text becomes each
# harness's context file (CLAUDE.md / AGENTS.md), so its shape changes model
# behavior, not only its content. Every rule below cites a published result.
# Keep new sections consistent with these principles.
#
# 1. Short, and ordered by stakes. Models attend most to the start and end of a
#    context and lose information held in the middle. So the maxLines cap is
#    deliberate, and the highest-stakes section (Prohibitions) renders last to
#    take the recency position.
#    Liu et al., "Lost in the Middle: How Language Models Use Long Contexts,"
#    TACL 2024 (arXiv:2307.03172).
#
# 2. Checkable, not vague. Instruction-following is measured on verifiable
#    instructions with exact counts and exact tokens. So rules state numbers
#    and named conditions, not "prefer" or "as needed."
#    Zhou et al., "Instruction-Following Evaluation for Large Language Models,"
#    2023 (arXiv:2311.07911).
#
# 3. State the positive action. Models reason poorly under negation, so each
#    "Never X" prohibition also names the action to take instead when one
#    exists, and Conventions use positive imperatives.
#    Truong et al., "Language Models Are Not Naysayers: An Analysis of Language
#    Models on Negation Benchmarks," *SEM 2023 (arXiv:2306.08189).
#
# 4. One term per concept; no conflicting rules. Fragmented or ambiguous
#    wording lowers instruction-following, so this file reuses one name per
#    concept and removes duplicate rules.
#    Schulhoff et al., "The Prompt Report: A Systematic Survey of Prompting
#    Techniques," 2024 (arXiv:2406.06608).
let
  subagents = import ../subagents;

  formatSkillsBlock =
    skills:
    let
      firstSentence =
        s:
        let
          parts = builtins.split "\\." s;
          chunks = builtins.filter builtins.isString parts;
          first = if chunks == [ ] then s else builtins.head chunks;
        in
        first;
      entries = builtins.attrValues (
        builtins.mapAttrs (name: desc: "- `${name}` · ${firstSentence desc}") skills
      );
    in
    if entries == [ ] then "(no skills registered)" else builtins.concatStringsSep "\n" entries;

  makeInstructions =
    {
      localSkillDescriptions,
      openspecVersion,
      skillsRoot ? "~/.claude/skills",
    }:
    let
      skillsList = formatSkillsBlock localSkillDescriptions;

      sections = {
        stack = ''
          ## Stack

          - nix-darwin + home-manager + nix flakes (Apple Silicon, NixOS)
          - openspec ${openspecVersion} via `overlays/openspec.nix` (custom schema: `rosh-spec-driven`)
          - Agent tooling: claude-code, codex, gemini, cursor, aider (all configured from `modules/home/programs/llm/`)
          - Shell: zsh; scripts in `hack/` are bash with `set -euo pipefail`, formatted by `shfmt -i 2 -ci -sr -s`
          - Formatter: `nixfmt-rfc-style` via `nix fmt`
          - Session manager: seshy (`sy`) for multi-repo feature work via git worktrees; sessions at `~/.local/state/seshy/sessions/`
        '';

        commands = ''
          ## Commands

          ```bash
          nix flake check          # validate flake (run before commits)
          nh darwin build          # build current host config (no system change)
          nh darwin switch         # apply config to system (use deliberately)
          nix fmt                  # format all Nix files
          task fmt:sh              # format hack/ shell scripts
          task fmt:sh:check        # verify shell formatting only
          task openspec:sync       # detect drift in the forked openspec schema
          ./hack/update-pi.sh      # report pi package drift
          openspec schema validate rosh-spec-driven
          sy list                  # list active seshy sessions
          sy new <name> [repos...] # create session with worktrees (explicit repos = non-interactive)
          sy status <name>         # inspect session repos and branches
          sy path <name>           # print session directory (for cd / script use)
          specutil graph --as mermaid  # cross-change dependency DAG
          specutil tui             # interactive spec lifecycle kanban
          specutil serve           # HTML DAG visualization (opens browser)
          specutil render --as rfc|design|tickets --change <name>
          specutil plan --target linear|notion --change <name>
          ```
        '';

        conventions = ''
          ## Conventions

          - Normative keywords (MUST/SHOULD/MAY) here and in skills follow RFC 2119 (https://datatracker.ietf.org/doc/html/rfc2119); "never"/"always" rules are MUST-level
          - Conventional commits, title-only, no body
          - One concern per commit; no formatting-only mixed with behavioral changes
          - Read context files (`AGENTS.md`, `openspec/`, `.sysinit/lessons.md`) before authoring
          - Edit existing files; create a new file only when no existing file can hold the change
          - Skills are the source of truth for domain rules; consult them via `${skillsRoot}/`
          - Use the globally managed OpenSpec CLI/skills when OpenSpec is relevant; run `openspec init` only to create project artifacts, not to install workflow support
          - On unexpected errors: stop, preserve evidence, fix root cause (no `--no-verify`)
          - Use `nix-shell` / `nix develop` for dependencies; avoid global installers
          - Default to `ast-grep`/`sg` (or the ast-grep MCP) for any structural code search; reserve `grep`/`rg` for literal text. See the `search-code-routing` skill.
          - Use Explore as the explicit planning subagent for discovery/scoping work; prefer librarian for external docs/code and oracle for deep architecture review
          - For multi-repo feature work, start a seshy session: `sy new <name> [repos...]`; never run bare `sy` (opens interactive picker)
          - openspec and seshy are first-class: check for active openspec changes (`openspec/changes/`) and seshy sessions (`sy list`) before scoping new work
        '';

        communication = ''
          ## Communication

          Governs how you write output: chat replies, PR bodies, review comments, docs. Code comments and commits keep their own skills (`writing-code-comments`, `writing-commit-message`). For longer prose in Roshan's name, also apply `writing-tone`.

          Standards basis: ISO 24495-1:2023 (relevant, findable, understandable, usable); W3C Cognitive Accessibility Guidance (clear words, literal language, short text, separate steps, no reliance on memory); US Plain Writing Act (understandable on first reading); JAN ADHD guidance (written, structured, step-by-step instructions).

          - Write in Simplified Technical English (ASD-STE100, https://www.asd-ste100.org/). You MUST: use one instruction per sentence; keep procedure sentences to 20 words or fewer and descriptive sentences to 25 or fewer; keep paragraphs to 6 sentences or fewer; use active voice; use simple present, past, future, or imperative verbs; avoid gerund chains and stacked auxiliaries.
          - One word, one meaning: pick a single term for a concept and reuse it. You MUST NOT vary the term for style.
          - Use only terms already established in this repo, its skills, or the standard vocabulary of the tool at hand (Nix, git, k8s, the shell). You MUST NOT invent metaphors, idioms, or coined phrases. Banned examples of made-up or off-convention terms: "belt-and-suspenders", "rung", "north star", "load-bearing", "table stakes". If a term does not appear in this repo or the tool's own docs, do not use it.
          - Do not use em-dashes in prose. Use a comma, colon, or new sentence instead.
          - Do not bold the first term in a bullet. Use sub-bullets for detail instead.
          - Shape output so a reader with ADHD can act on it:
            - Lead with the action or answer, not preamble or context.
            - Number multi-step work; each step is one bounded action.
            - End with the next concrete action.
            - Restate the current state each turn; the reader does not hold context between messages.
            - Give concrete size or time estimates, not vague ones.
            - Make completed work visible; state errors matter-of-factly (cause, then fix).
            - Cap lists at 5 items; rank or split longer lists.
            - No preamble, recap, or pleasantries.
          - Break these rules only when: the user asks you to "explain" or "walk through", you must confirm a destructive action, you are naming the wrong assumption in a debug spiral, or the request has real ambiguity.

          Good: "Run `nix flake check`. It found 2 errors. Fix line 42, then rerun."
          Avoid: "You might want to consider running the formatter. It could potentially help with linting."
          Good bullet: "- nix fmt: formats all Nix files" or "- nix fmt" with a sub-bullet for detail.
          Avoid bullet: "- **nix fmt** formats all Nix files" (bold term diminishes clarity; use plain text).
        '';

        skills = ''
          ## Skills

          Skills live at `${skillsRoot}/<name>/SKILL.md`, generated from `modules/home/programs/llm/skills/default.nix`.

          ${skillsList}
        '';

        prohibitions = ''
          ## Prohibitions

          - Never commit unless directed; stage the change and propose a message instead
          - Never use `--no-verify`, `--no-gpg-sign`, or other hook-bypass flags; fix the failing hook instead
          - Never use `any` or type suppressions without explicit permission
          - Never add emojis to code or generated files
          - Never run destructive git commands (`reset --hard`, `clean -f`, `branch -D`, force-push) without explicit instruction
          - Never edit hand-managed configuration when a Nix-managed equivalent exists; edit the Nix source that generates it instead
          - Never auto-update vendored upstream content; let the sync scripts surface drift instead
        '';

        context = ''
          ## Context

          - `.sysinit/` is gitignored scratch space for lessons and PRD notes; check `.sysinit/lessons.md` at session start
          - OpenSpec artifacts live at `openspec/changes/<name>/`; the active schema is `rosh-spec-driven`
          - User-level `~/.config/git/ignore` already excludes `**/.claude/`, `**/.agents/`; do not duplicate in per-project `.gitignore`
          - Seshy sessions live at `~/.local/state/seshy/sessions/`; run `sy list` to discover active sessions before starting new feature work
          - Cross-harness memory: `basic-memory` MCP is available to all agents; use it for notes and context that must survive across harness boundaries
          - specutil is on PATH: use `specutil graph --as mermaid` to show the cross-change dependency DAG before planning, `specutil tui` for the lifecycle kanban, and `specutil serve` to open the HTML visualization
          - When exploring or planning work that touches openspec changes, always call `specutil graph` first to understand the current DAG
        '';
      };

      order = [
        "stack"
        "commands"
        "conventions"
        "communication"
        "skills"
        "context"
        "prohibitions"
      ];

      rendered = builtins.concatStringsSep "\n" (map (key: sections.${key}) order);

      lineCount =
        let
          parts = builtins.split "\n" rendered;
          stringParts = builtins.filter builtins.isString parts;
        in
        builtins.length stringParts;

      maxLines = 200;
    in
    if lineCount > maxLines then
      throw "instructions.nix: rendered context exceeds ${toString maxLines} lines (got ${toString lineCount}). Trim sections or split per-agent extensions."
    else
      rendered;
in
{
  inherit makeInstructions;
  inherit subagents;
  inherit (subagents) formatSubagentAsMarkdown;
  # subagentDefs: the subagent attrset without the formatter, so callers can
  # iterate over agent definitions without the filterAttrs workaround.
  subagentDefs = builtins.removeAttrs subagents [ "formatSubagentAsMarkdown" ];
}
