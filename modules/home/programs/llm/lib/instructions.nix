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

  registry = import ../harnesses/registry.nix;

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
          - Note a non-obvious change as you make it, answer a note the owner left you, and replace your own note once the code outgrows it; the `note` skill holds the rules
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

    Zinsser's four principles decide anything the rules below leave open, in
    this order when they conflict:

    - Clarity. The reader must not have to read a sentence twice.
    - Simplicity. Cut every word that does no work.
    - Brevity. Say it once, in the fewest sentences that stay clear.
    - Humanity. Write to a person, not at one. Warmth is not padding, and
      neither is admitting what you do not know.

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

    Cut these patterns on sight. Each one marks the text as model-written.

    - Negative parallelism, the strongest tell: "it is not X, it is Y", "not
      just X but Y", "X rather than Y" used as a frame. Delete the dismissed
      half and state only the thing you mean.
    - Tricolon: three adjectives or three parallel phrases that make a thin
      point look complete. Use one precise item, or two.
    - Staccato stacking: fragments of equal length with no connective tissue.
      Vary sentence length instead.
    - Hedge before the claim: "it is worth noting that", "this is nuanced",
      "it could be argued". Make the claim and defend it.
    - Filler opener: "great question", "certainly", "in today's fast-paced",
      "let us dive in". Start with the substance.
    - Significance inflation: "pivotal", "a significant shift", "a broader
      movement". Say what happened, and when.
    - Trailing "-ing" analysis: "...reflecting its continued relevance." Delete
      the clause. The sentence stands without it.
    - Marketing verbs: seamlessly, effortlessly, leverage, unlock, empower,
      robust, comprehensive, streamline, delve, showcase, foster.
    - A question you answer yourself in the next sentence.
    - Sandwich ending: a restatement of the opening, a prediction, or a call to
      action. End on the next concrete action.
    - Uniform shape: every sentence the same length, every paragraph the same
      size, every bullet the same grammatical form.

    Replace every adjective with a number, every adverb with a comparison, and
    every vague verb with a concrete one.

    <examples>
    <example>
    <bad>You might want to consider running the formatter. It could help.</bad>
    <good>Run `nix fmt`. It rewrites 3 files.</good>
    </example>
    <example>
    <bad>- **nix fmt** formats all Nix files</bad>
    <good>- nix fmt: formats all Nix files</good>
    </example>
    <example>
    <bad>This isn't a lint failure, it's a design problem.</bad>
    <good>The lint passes. Two modules still write the same path.</good>
    </example>
    <example>
    <bad>The check is fast, robust, and comprehensive.</bad>
    <good>The check runs in 4s over every `.lua` file in the wezterm tree.</good>
    </example>
    <example>
    <bad>It's worth noting that this could potentially break on Linux.</bad>
    <good>This breaks on Linux. The overlay is not gated on `isDarwin`.</good>
    </example>
    </examples>

    Write every rule in a skill, a doc, or an instruction with one paired
    example. Wrap prose pairs in `<example>` with a `<bad>` and a `<good>`
    inside, and group several in `<examples>`. Inside a code fence, mark the
    pair with `# good` and `# bad` comments instead, since XML tags there are
    not valid code. Give the reason with the rule: a rule that says why
    generalizes, and a bare prohibition does not.
  '';

  makeInstructionsWithStyle =
    args: makeInstructions args + "\n## Output Style\n\n" + outputStyleRules;

in
{
  inherit makeInstructions makeInstructionsWithStyle outputStyleRules;
  inherit (subagents) formatSubagentAsMarkdown;
  subagentDefs = builtins.removeAttrs subagents [ "formatSubagentAsMarkdown" ];
}
