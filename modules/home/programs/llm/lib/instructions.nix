# Instruction-writing principles for this file. The rendered text becomes each
# harness's global context file (~/.claude/CLAUDE.md, ~/.config/*/AGENTS.md), so
# its shape changes model behavior, not only its content. Keep new sections
# consistent with these principles.
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
#    concept (see vocab.nix for the per-harness names) and removes duplicate
#    rules.
#    Schulhoff et al., "The Prompt Report: A Systematic Survey of Prompting
#    Techniques," 2024 (arXiv:2406.06608).
#
# 5. Global means cross-repo. This file is loaded in every repository, so it
#    carries only rules that hold everywhere. Facts about one repository belong
#    in that repository's AGENTS.md, and a domain's rules belong in that
#    domain's skill. Loading either one globally spends context in every
#    session that does not need it.
#    Anthropic, "The New Rules of Context Engineering for Claude 5-Generation
#    Models," 2026 (progressive disclosure; single source).
#
# 6. State a fact once, in the layer that owns it. A rule repeated across the
#    context file, a skill, and a tool description does not reinforce itself; it
#    creates three places to drift. Writing rules live in the output style, tool
#    routing lives in the tool's skill, and {{agent}} selection lives in the
#    {{agent}} definition.
#    Same source as principle 5 (repetition -> single source).
{ lib }:
let
  subagents = import ../subagents { inherit lib; };
  vocab = import ./vocab.nix { inherit lib; };

  # Names only, and only for harnesses that cannot load a skill. Every harness
  # with a skill loader already surfaces each skill's own description from its
  # skills tree, so listing them here says the same thing twice. Codex and
  # copilot have no loader, but their Read tool still reaches the tree, so they
  # get the names as a pointer.
  formatSkillsBlock =
    skills:
    let
      names = builtins.attrNames skills;
    in
    if names == [ ] then
      "(no skills registered)"
    else
      "Available: " + builtins.concatStringsSep ", " (map (n: "`${n}`") names);

  # Where each configured harness reads its global context, or why it does not
  # get one. Every harness config imported by `default.nix` must appear here, so
  # adding a harness without deciding this fails the build rather than shipping
  # an agent that never sees the conventions or the prohibitions.
  #
  # A path is only declared once it has been confirmed against the installed
  # build. A guessed path produces a file nothing reads, which looks like
  # coverage and is not.
  harnessCoverage = {
    claude = "~/.claude/CLAUDE.md";
    codex = "codex `context`";
    gemini = "~/.agents/AGENTS.md";
    opencode = "~/.config/opencode/AGENTS.md";
    amp = "~/.config/amp/AGENTS.md";
    crush = "~/.config/crush/AGENTS.md";
    devin = "~/.config/devin/AGENTS.md";
    pi = "~/.pi/agent/AGENTS.md";
    goose = "~/.config/goose/.goosehints";
    cursor = "~/.cursor/rules/always.mdc";
    copilot = "~/.copilot/copilot-instructions.md";
  };

  coveredHarnesses = builtins.attrNames harnessCoverage;

  harnessesWithoutSkillLoader = [
    "codex"
    "copilot"
  ];

  makeInstructions =
    {
      harness,
      localSkillDescriptions,
      skillsRoot ? "~/.claude/skills",
    }:
    let
      skillsList = formatSkillsBlock localSkillDescriptions;

      sections = {
        conventions = ''
          ## Conventions

          - Normative keywords (MUST/SHOULD/MAY) here and in skills follow RFC 2119 (https://datatracker.ietf.org/doc/html/rfc2119); "never"/"always" rules are MUST-level
          - Read the repository's own context before authoring: `AGENTS.md`, `openspec/`, `.sysinit/lessons.md`
          - Write code that reads like the code around it: match its comment density, naming, and idiom
          - Edit an existing file; create a new file only when no existing file can hold the change
          - Conventional commits, title-only, no body; one concern per commit, and no formatting-only change mixed with a behavioral one
          - Get dependencies from `nix-shell` or `nix develop`, not from a global installer
          - On an unexpected error: stop, preserve the evidence, fix the root cause
          - Skills hold the domain rules and the tool routing; load the skill from `${skillsRoot}/` instead of working from memory
          - Pick a {{agent}} by reading its own definition; the definitions carry the use-when and avoid-when rules
          - openspec and seshy are machine-wide: check `openspec/changes/` and `sy list` before you scope new work
        '';

        skills = ''
          ## Skills

          Skills live at `${skillsRoot}/<name>/SKILL.md`. This harness has no skill loader, so read a skill's file directly when its name matches the task.

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
      };

      order = [
        "conventions"
      ]
      ++ lib.optional (builtins.elem harness harnessesWithoutSkillLoader) "skills"
      ++ [
        "prohibitions"
      ];

      rendered = vocab.applyVocab harness (
        builtins.concatStringsSep "\n" (map (key: sections.${key}) order)
      );

      lineCount =
        let
          parts = builtins.split "\n" rendered;
          stringParts = builtins.filter builtins.isString parts;
        in
        builtins.length stringParts;

      # Sized to the cross-repo rules plus headroom for one more section. A
      # breach means a repository fact or a domain rule leaked in; move it to
      # that repository's AGENTS.md or to the owning skill instead of raising
      # the cap.
      maxLines = 45;
    in
    if !(harnessCoverage ? ${harness}) then
      throw "instructions.nix: harness '${harness}' renders context but is not declared in harnessCoverage. Add its confirmed global path, or null with the reason it is exempt."
    else if lineCount > maxLines then
      throw "instructions.nix: rendered context exceeds ${toString maxLines} lines (got ${toString lineCount}). Move repo-specific facts to that repo's AGENTS.md and domain rules to the owning skill."
    else
      rendered;

  # Compact, operationally-enforced output rules. Sole source for how the model
  # writes: no context section restates them. No frontmatter — that is added by
  # the consumer (claude.nix wraps these in the output-style file header;
  # makeInstructionsWithStyle appends them as a plain section).
  #
  # These caps are accessibility requirements (ISO 24495-1:2023, W3C Cognitive
  # Accessibility Guidance, US Plain Writing Act, JAN ADHD guidance), not
  # guardrails against model error, so they stay stated as exact numbers rather
  # than as judgment calls.
  outputStyleRules = ''
    Write all output in Simplified Technical English (ASD-STE100).

    Standards basis: ISO 24495-1:2023 (relevant, findable, understandable,
    usable); W3C Cognitive Accessibility Guidance (clear words, literal language,
    short text, separate steps, no reliance on memory); US Plain Writing Act
    (understandable on first reading); JAN ADHD guidance (written, structured,
    step-by-step instructions).

    Scope: chat replies, PR bodies, review comments, and docs. Code comments and
    commit messages follow the `writing-code-comments` and
    `writing-commit-message` skills. Longer prose in Roshan's name also follows
    `writing-tone`.

    - Use one instruction per sentence. Keep procedure sentences to 20 words or
      fewer and descriptive sentences to 25 or fewer. Keep paragraphs to 6
      sentences or fewer.
    - Use active voice and simple present, past, future, or imperative verbs.
      Avoid gerund chains and stacked auxiliaries.
    - One word, one meaning: pick a single term for a concept and reuse it. Do
      not vary the term for style.
    - Use only terms established in this repo, its skills, or the standard
      vocabulary of the tool at hand. Do not invent metaphors, idioms, or coined
      phrases.
    - Do not use em-dashes in prose. Use a comma, colon, or new sentence instead.
    - Do not bold the first term in a bullet. Use sub-bullets for detail instead.
    - Shape output so a reader with ADHD can act on it: lead with the action or
      answer; number multi-step work; end with the next concrete action; restate
      the current state each turn; give concrete size or time estimates; make
      completed work visible; state errors matter-of-factly; cap lists at 5 items.
    - No preamble, recap, or pleasantries.
    - Break these rules only when the user asks you to explain or walk through, you
      must confirm a destructive action, you name the wrong assumption in a debug
      spiral, or the request has real ambiguity.

    Good: "Run `nix flake check`. It found 2 errors. Fix line 42, then rerun."
    Avoid: "You might want to consider running the formatter. It could help."
    Good bullet: "- nix fmt: formats all Nix files"
    Avoid bullet: "- **nix fmt** formats all Nix files" (bold term; use plain text)
  '';

  # For harnesses without a native output-style layer, appends outputStyleRules
  # at the recency position (after all context sections) so the model sees the
  # operative rules last. Claude uses its native outputStyle mechanism instead.
  makeInstructionsWithStyle =
    args: makeInstructions args + "\n## Output Style\n\n" + outputStyleRules;

in
{
  inherit makeInstructions makeInstructionsWithStyle outputStyleRules;
  inherit harnessCoverage coveredHarnesses;
  inherit subagents;
  inherit (subagents) formatSubagentAsMarkdown;
  # subagentDefs: the subagent attrset without the formatter, so callers can
  # iterate over agent definitions without the filterAttrs workaround.
  subagentDefs = builtins.removeAttrs subagents [ "formatSubagentAsMarkdown" ];
}
