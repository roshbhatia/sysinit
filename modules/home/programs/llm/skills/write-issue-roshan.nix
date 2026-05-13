''
  # Writing Roshan-style GitHub issues

  Distilled from issues the user has opened across multiple projects
  (his own + upstream OSS).

  ## First, read the repo's contribution docs

  Many projects have explicit rules for issue filing. Check before drafting:

  ```bash
  ls CONTRIBUTING.md .github/CONTRIBUTING.md \
     .github/ISSUE_TEMPLATE/ \
     SUPPORT.md .github/SUPPORT.md 2>/dev/null
  ```

  Things to extract:

  - **Where to ask vs. file**: some repos route questions to Discussions,
    Discord, or a forum, and only accept bug reports / feature requests
    in Issues. Honor it.
  - **Issue templates**: `.github/ISSUE_TEMPLATE/*.md` defines the
    canonical shapes (bug, feature, etc.). Use the matching template
    verbatim. GitHub will auto-select it via the `?template=` URL
    param if you `gh issue create --web`.
  - **Reproduction requirements**: many projects require minimal repros,
    version info, OS info. Some have explicit "do not file without X"
    rules.
  - **Duplicate-search expectation**: most repos expect you to search
    open + closed issues first. Cite the search you did in the body.

  When the repo provides no guidance, fall back to the structure below.

  ## Title

  Lowercase sentence fragment describing the desired state or the bug
  symptom. No period at end. No bracketed prefixes (`[BUG]`,
  `[FEATURE]`).

  Real exemplars:

  - "add a commit hook or another kind of hook to automatically run db
    migrations when schemas change"
  - "Open source the `docker init` feature"
  - "MS Teams integration subtitle contains placeholder text"
  - "Type casting/type translation errors cause apply to error out for
    `kubernetes_manifest` resource"
  - "SUMOLOGIC_ACCESSID and SUMOLOGIC_ACCESSKEY aren't picked up from
    the environment during provider initialization"

  Patterns:
  - **Bug titles**: name the broken behavior, optionally with the affected
    resource/identifier in backticks.
  - **Feature titles**: describe the desired capability as an imperative
    or noun phrase.
  - **Domain identifiers in backticks**: `kubernetes_manifest`,
    `docker init`, `SUMOLOGIC_ACCESSID`. No expansion.
  - **Title-case for proper nouns only** (MS Teams, SUMOLOGIC env vars).
    The rest of the title is lowercase.

  ## Body shape — when the repo provides a template

  Follow the template. Fill every section the template defines. Most
  upstream OSS issue templates expect:

  - **Steps to reproduce** (numbered, executable)
  - **Expected behavior**
  - **Actual behavior**
  - **Environment** (versions, OS, relevant config)

  Real exemplar pattern from a terraform-provider issue:

  ```
  **steps to reproduce**
  1. Have variables exported in the environment.
  2. Follow environment variable authentication strategy found in <URL>
  3. Try to apply with those variables set.

  **expected behavior**
  Provider authenticates using the env vars.

  **actual behavior**
  Provider errors with "no credentials configured".

  **versions**
  - terraform: 1.5.7
  - provider: 2.30.0
  ```

  Lowercase section headers when matching the template's style; preserve
  template-defined formatting verbatim.

  ## Body shape — when there's NO template

  Free-form but disciplined:

  1. **One-sentence problem statement** as the first line. No "Hi! I'd
     like to…" preamble.
  2. **Steps to reproduce** as a numbered list if the issue is a bug.
  3. **Expected vs actual** as a single line each when the behavior is
     simple.
  4. **Environment fingerprint** at the bottom: tool versions,
     OS, relevant config snippets in fenced blocks.

  For feature requests, the shape inverts:

  1. **Use case** as the first paragraph: what are you trying to do,
     and what's the friction today.
  2. **Proposal** as the second paragraph: what change would unblock the
     use case.
  3. **Alternatives considered**: what you tried or thought about and
     why it didn't work.

  ## Vocabulary

  - **Use the project's domain vocabulary verbatim**. If they call it a
    "Workspace", don't call it a "project". If their docs say "module",
    don't say "package".
  - **Reproductions are deterministic**. "Sometimes errors out" is not a
    reproduction; convert to the minimal sequence that reliably reproduces.
  - **Cite versions in backticks**: `1.5.7`, `2.30.0`. Cite OSes by
    canonical name (macOS 14.4, Ubuntu 22.04).

  ## What to avoid

  - **Em-dashes scattered through prose** for elaboration. PR-review
    voice doesn't translate to issue bodies — issues are more formal,
    more structured, less conversational.
  - **Emojis** anywhere.
  - **Apologetic openers**: "Sorry if this is the wrong place to ask…".
  - **Stack traces inline without a fenced block**. Always fence them.
  - **Speculation about root cause** unless you have evidence. The issue
    describes the symptom; the maintainer diagnoses.
  - **"+1" comments on existing issues**. If you have new info, add it;
    if you don't, use the 👍 reaction instead.

  ## Negative scenarios

  - **WHEN** opening an issue against an upstream OSS project that has
    an issue template
  - **THEN** follow the template exactly — don't substitute your own
    structure even if the template feels redundant.

  - **WHEN** filing what you think is a bug but reproduction is flaky
  - **THEN** spend more time isolating the reproduction BEFORE filing.
    Half a repro wastes maintainer attention; a clean repro respects it.
''
