''
  # Writing Roshan-style commit messages

  Match the user's commit-message conventions exactly. Distilled from his
  git history. Mandatory rules (already in AGENTS.md, repeated here for
  the trigger context):

  ## First, check the repo's contribution rules

  This skill's conventions are the default. **The repo always overrides.**
  Before committing in a repo you don't own, sweep for:

  ```bash
  ls CONTRIBUTING.md .github/CONTRIBUTING.md DCO 2>/dev/null
  grep -l "Signed-off-by\\|DCO\\|commit format" \
    CONTRIBUTING.md .github/CONTRIBUTING.md 2>/dev/null
  ```

  Common overrides:

  - **DCO / Signed-off-by required**: add `--signoff` to `git commit`.
    The `Signed-off-by: <name> <email>` trailer goes in the commit body,
    which overrides this skill's "title-only, no body" rule.
  - **Different commit format**: if the repo requires a non-conventional
    format (e.g., `[component] message` or `JIRA-123: message`), use it.
  - **Issue-link syntax**: some repos require `Refs #NN`, `Fixes #NN`,
    or `Closes JIRA-XXX` in the commit. Honor it.
  - **Co-author conventions**: some repos require / forbid
    `Co-authored-by:` lines.

  When the user is committing in their own repos (`roshbhatia/*`,
  `ross-corp/*`, `pinginc/*` per his usage), follow this skill's
  defaults below. When committing upstream, the repo's `CONTRIBUTING.md`
  is the authority.

  ## Required shape

  ```
  <type>(<scope>): <subject>
  ```

  - `type` ∈ `feat`, `fix`, `refactor`, `chore`, `docs`, `test`, `perf`,
    `build`, `ci`. Never improvise outside this set.
  - `scope` is the affected module name, lowercase, kebab-case if multi-word.
    Common scopes in this repo: `pi`, `llm`, `claude`, `gemini`, `goose`,
    `codex`, `cursor`, `aider`, `opencode`, `openspec`, `hack`, `flake`.
  - `subject` is a lowercase imperative-mood sentence fragment.
  - No period at the end of the subject.
  - No body. The title carries everything.

  ## Subject conventions

  - **Imperative mood**: "restore X", "drop Y", "bump Z". Not "restored",
    "dropping", "bumped".
  - **Lowercase throughout** (after the colon).
  - **Backticked identifiers** when they're load-bearing:
    `feat(pi): bump pi-coding-agent to 0.74.0 from earendil-works/pi`.
  - **Two-clause subjects** join with `;` for contingency or reason:
    `fix(pi): restore permission-system; sqlite blame was on samfp/pi-memory`
    `fix(pi): drop permission-system and samfp/pi-memory pending node:sqlite support`
  - **No emojis**. Ever.
  - **Domain abbreviations are fine without expansion**: sqlite, MCP, OAuth,
    npm, TUI, CLI.

  ## Exemplars (real commits)

  ```
  feat(claude): auto-allow read-only inspection commands
  refactor(claude): consume harness-kit and canonical allowlist
  feat(llm): scaffold harness-kit and canonical allowlist
  refactor(llm): migrate small-config harnesses to harness-kit
  chore(openspec): archive refresh-pi-stack change
  fix(pi): bump pi-coding-agent to 0.74.0 from earendil-works/pi
  fix(pi): restore permission-system; sqlite blame was on samfp/pi-memory
  feat(openspec): require pattern reuse, progressive rollout, and human verification gates
  feat(pi): add openspec-status read-only extension for the status line
  feat(hack): add openspec and AGENTS.md drift detection scripts
  ```

  ## What to avoid

  - Capitalizing the subject after the colon ("feat: Add foo" → wrong).
  - Trailing periods ("feat: add foo." → wrong).
  - Padding words: "feat: just adding foo", "fix: small tweak to bar".
  - Vague subjects: "chore: misc fixes", "fix: bug" — name what.
  - Multi-line commits with a body. The user explicitly does not write
    commit bodies. If context doesn't fit in the subject, the change is
    too big for one commit.
  - "Co-Authored-By" lines unless the user explicitly directed them
    (they're acceptable for agent-authored commits with explicit consent).

  ## Negative scenarios

  - **WHEN** asked to commit a sprawling change touching many concerns
  - **THEN** propose splitting into multiple commits, one concern each.
    Do not author a single commit with a multi-paragraph body.

  - **WHEN** the subject doesn't fit comfortably on one line (~72 chars)
  - **THEN** simplify the subject by removing prose, not by overflowing.
    Use scope to absorb noun phrases.
''
