''
  # Opinionated commit messages

  A terse, opinionated style guide for commit subjects. The defaults below describe a single voice; repo conventions always override.

  Provenance: derived from a personal-OSS corpus of 295 PRs and 504 commits authored before 2024-06-01, plus the standing rules in `~/.claude/CLAUDE.md`.

  ## First, check the repo's contribution rules

  This skill's defaults are the fallback. The repo always wins. Before committing in a repo you don't own, sweep for:

  ```bash
  ls CONTRIBUTING.md .github/CONTRIBUTING.md DCO 2>/dev/null
  grep -l "Signed-off-by\\|DCO\\|commit format" \
    CONTRIBUTING.md .github/CONTRIBUTING.md 2>/dev/null
  ```

  Common overrides:

  - DCO / Signed-off-by required: add `--signoff` to `git commit`. The `Signed-off-by: <name> <email>` trailer goes in the commit body. This overrides the title-only default below.
  - Different commit format: if the repo requires a non-conventional shape (e.g. `[component] message`, `JIRA-123: message`), use it verbatim.
  - Issue-link syntax: some repos require `Refs #NN`, `Fixes #NN`, or `Closes JIRA-XXX` in the commit. Honor it.
  - Co-author conventions: some repos require, and others forbid, `Co-authored-by:` trailers.

  When operating in a repo with no contribution docs, apply the defaults below without modification.

  ## Required shape

  ```
  <type>(<scope>): <subject>
  ```

  - `type` is preferred from this set: `feat`, `fix`, `refactor`, `chore`, `docs`, `test`, `perf`, `build`, `ci`, `revert`. Do not improvise outside this set unless the repo's conventions require it.
  - `type` is preferred but not required. Bare subjects (no `type:` prefix) are observed in the historical corpus and are acceptable when the change does not fit cleanly into a single type.
  - `scope` is optional. When used, it is the affected module name, lowercase, kebab-case if multi-word. Common in-this-config scopes: `pi`, `llm`, `claude`, `gemini`, `goose`, `codex`, `cursor`, `aider`, `opencode`, `openspec`, `hack`, `flake`.
  - `subject` is a sentence fragment in imperative mood.
  - Lowercase is preferred for the subject. About 80% of historical subjects are fully lowercase; 20% begin with a capital, usually when the subject opens with an identifier or a ticket ID. Do not capitalize unnecessarily, but do not force lowercase when a proper noun or identifier begins the subject.
  - No period at the end of the subject.
  - No body by default. The title carries everything.

  ## Subject conventions

  - Imperative mood: `restore X`, `drop Y`, `bump Z`. Not `restored`, `dropping`, `bumped`.
  - Backtick identifiers when they are load-bearing: ``feat(pi): bump pi-coding-agent to 0.74.0 from earendil-works/pi``.
  - Single clause per subject. Do not join two clauses with `;`. Do not use em-dash elaboration in the subject. If two ideas need to be expressed, they are two commits.
  - No emojis in subjects, ever.
  - Domain abbreviations are fine without expansion: sqlite, MCP, OAuth, npm, TUI, CLI.
  - Length: prefer under 72 characters, tolerate up to ~100 when the subject would otherwise lose meaning. Do not pad to consume the budget.

  ## Historical variant: ticket-id prefix inside the subject

  In the personal-OSS corpus this skill is grounded in, 83% of subjects carried a tracker ticket ID inside the subject body:

  ```
  <type>: <PROJECT-NNN>: <subject>
  ```

  Where `PROJECT-NNN` matches `[A-Z]{2,}[0-9]*-[0-9]+`. This is a recognized historical variant. Use it when a Linear, JIRA, or other tracker ticket is in active scope for the change. Do not invent a ticket ID, and do not apply this shape to current work that has no active tracker. Bare subjects without a ticket prefix are equally acceptable.

  When the ticket ID is used, the conv-commit type may still appear (`fix: PROJECT-NNN: <subject>`), or the ticket ID may stand alone (`PROJECT-NNN: <subject>`). Both are observed in the historical corpus.

  ## Exemplars

  Current in-this-config style, no ticket in scope:

  ```
  feat(claude): auto-allow read-only inspection commands
  refactor(claude): consume harness-kit and canonical allowlist
  chore(openspec): archive refresh-pi-stack change
  fix(pi): bump pi-coding-agent to 0.74.0 from earendil-works/pi
  feat(openspec): require pattern reuse, progressive rollout, and human verification gates
  feat(pi): add openspec-status read-only extension for the status line
  ```

  Historical exemplars from the pre-2024 corpus (illustrative of the ticket-prefix variant; the concrete project codes shown here are historical and not vocabulary for new work):

  ```
  fix: OWL-1381: make healthcheck failure threshold configurable
  feat: OWL-1397: add slos for each env
  chore: OWL-2381: archive (lrl) tracking-service
  fix(ingress): OWL-1820: add ELBSecurityPolicy-TLS-1-2-2017-01
  feat(auth)!: OWL-1326: use new permissions token key
  TO-291: fixup monitor type for activity/batch alert and elevated 5xx
  ```

  Note the `!` after the type for breaking changes in conv-commits, used in both eras.

  ## What to avoid

  - Capitalizing the subject after the colon without reason. Lowercase is preferred. Capitalize only when an identifier or proper noun opens the subject.
  - Trailing periods (`feat: add foo.`).
  - Padding words: `feat: just adding foo`, `fix: small tweak to bar`.
  - Vague subjects: `chore: misc fixes`, `fix: bug`. Name what.
  - Multi-line commits with a body. The default is title-only. If context does not fit in the subject, the change is too big for one commit.
  - Semicolon-joined two-clause subjects. If you have two ideas, you have two commits.
  - Em-dash elaboration in the subject.
  - Emojis, anywhere.
  - `Co-Authored-By` / `Co-authored-by:` trailers unless the user has explicitly directed them.
  - "Generated with..." or other tool-attribution trailers unless the user has explicitly directed them.
  - Inventing a ticket ID when no tracker is in scope. The historical variant is opt-in, not enforced.
  - Bolded list rows (`- **Foo**: bar`) in any commit body, if a body is written at all.

  ## Negative scenarios

  - WHEN asked to commit a sprawling change touching many concerns
  - THEN propose splitting into multiple commits, one concern each. Do not author a single commit with a multi-paragraph body.

  - WHEN the subject does not fit comfortably on one line
  - THEN simplify the subject by removing prose. Use the optional `scope` to absorb noun phrases.

  - WHEN the user has no active tracker ticket but asks for a commit subject
  - THEN omit the ticket-prefix variant. Use either `<type>(<scope>): <subject>` or a bare subject. Do not invent a ticket ID.

  - WHEN tempted to add a second clause with `;` or `—` to fit more meaning into the subject
  - THEN rewrite to a single clause. The lost meaning belongs in a follow-up commit or in the PR body.

  - WHEN drafting and tempted to capitalize the first word for "professionalism"
  - THEN do not. Lowercase is the preferred default. Capitalize only when an identifier or proper noun opens the subject.
''
