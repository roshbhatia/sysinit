{ lib }:
let
  subagents = import ../subagents { inherit lib; };
  vocab = import ./vocab.nix { inherit lib; };

  formatSkillsBlock =
    skills:
    let
      names = builtins.attrNames skills;
    in
    if names == [ ] then
      "(no skills registered)"
    else
      "Available: " + builtins.concatStringsSep ", " (map (n: "`${n}`") names);

  # Both derived from the registry. A harness cannot be configured without a
  # context path or a skill-loader answer, because one entry supplies all three.
  registry = import ../harnesses/registry.nix;

  harnessCoverage = builtins.mapAttrs (_name: h: h.context) registry;

  coveredHarnesses = builtins.attrNames harnessCoverage;

  harnessesWithoutSkillLoader = builtins.attrNames (
    lib.filterAttrs (_name: h: !h.skillLoader) registry
  );

  makeInstructions =
    {
      harness,
      localSkillDescriptions,
      skillsRoot ? "~/.claude/skills",
      extraSections ? [ ],
    }:
    let
      skillsList = formatSkillsBlock localSkillDescriptions;

      sections = {
        conventions = ''

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

          Skills live at `${skillsRoot}/<name>/SKILL.md`. This harness has no skill loader, so read a skill's file directly when its name matches the task.

          ${skillsList}
        '';

        responsibility = ''

          - Treat model output as a draft until evidence verifies it
          - The user owns each decision and artifact; never claim approval on the user's behalf
          - Use models to sharpen reasoning, not to replace reading or understanding
          - Inspect the complete diff and run relevant checks before handoff
          - Keep shipped work understandable and maintainable without model assistance
          - Model review supplements human review; it never constitutes approval
        '';

        prohibitions = ''

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
        "responsibility"
        "prohibitions"
      ];

      base = builtins.concatStringsSep "\n" (map (key: sections.${key}) order);

      extraText = section: ''

        ${section.body}
      '';
      extras = builtins.concatStringsSep "\n" (map extraText extraSections);

      ownedTitles = [
        "Conventions"
        "Skills"
        "Responsibility"
        "Prohibitions"
        "Output Style"
      ];
      shadowedTitles = builtins.filter (t: builtins.elem t ownedTitles) (map (s: s.title) extraSections);

      rendered = vocab.applyVocab harness (
        base + lib.optionalString (extraSections != [ ]) "\n${extras}"
      );

      requiredResponsibilityRules = [
        "The user owns each decision and artifact"
        "Inspect the complete diff"
        "Model review supplements human review"
      ];
      missingResponsibilityRules = builtins.filter (
        rule: !(lib.hasInfix rule rendered)
      ) requiredResponsibilityRules;

      countLines =
        text:
        let
          parts = builtins.split "\n" text;
          stringParts = builtins.filter builtins.isString parts;
        in
        builtins.length stringParts;

      lineCount = countLines base;

      maxLines = 45;

      extraLineCount = countLines extras;
      maxExtraLines = 16;
    in
    if missingResponsibilityRules != [ ] then
      throw "instructions.nix: harness '${harness}' is missing responsibility rules: ${builtins.concatStringsSep ", " missingResponsibilityRules}"
    else if lineCount > maxLines then
      throw "instructions.nix: rendered context exceeds ${toString maxLines} lines (got ${toString lineCount}). Move repo-specific facts to that repo's AGENTS.md and domain rules to the owning skill."
    else if shadowedTitles != [ ] then
      throw "instructions.nix: sysinit.llm.instructions.extraSections shadows a section this repository owns: ${builtins.concatStringsSep ", " shadowedTitles}. Pick a distinct title."
    else if extraLineCount > maxExtraLines then
      throw "instructions.nix: sysinit.llm.instructions.extraSections exceeds ${toString maxExtraLines} lines (got ${toString extraLineCount}). A downstream rule that needs more room is a repository fact or a domain rule; move it to that repo's AGENTS.md or to the owning skill."
    else
      rendered;

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

  makeInstructionsWithStyle =
    args: makeInstructions args + "\n## Output Style\n\n" + outputStyleRules;

in
{
  inherit makeInstructions makeInstructionsWithStyle outputStyleRules;
  inherit harnessCoverage coveredHarnesses;
  inherit subagents;
  inherit (subagents) formatSubagentAsMarkdown;
  subagentDefs = builtins.removeAttrs subagents [ "formatSubagentAsMarkdown" ];
}
