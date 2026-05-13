''
  # Writing Roshan-style PR review / discussion comments

  Distilled from ~25 real review and discussion comments authored by the
  user. The voice is concise, diagnostic, and zero-hedge.

  ## Honor the repo's review conventions

  Before commenting on a PR or thread, check the repo for:

  ```bash
  ls CONTRIBUTING.md .github/CONTRIBUTING.md \
     CODE_OF_CONDUCT.md .github/CODE_OF_CONDUCT.md 2>/dev/null
  ```

  Some projects require specific review actions (e.g., conventional
  comments like `nit:`, `suggestion:`, `question:` prefixes). Some
  require an explicit approval/changes-requested verdict from
  CODEOWNERS. Some have a "block until fixed" vs "comment but
  approve" culture.

  Honor whatever the repo's culture is — the style traits below describe
  Roshan's *default* voice, which yields to project conventions when
  contributing elsewhere.

  ## Length

  1-3 sentences. Sometimes a single fragment ("Closing — stale Jules PR.").
  Rarely longer than 4 sentences. Never multi-paragraph preamble.

  ## Opening shape

  Lead with the verdict, then the reason. Never "I think we should…" or
  "It might be worth…". Direct claims.

  - **Verdict-first openers**: "Closing", "Closing as superseded by",
    "Build fails:", "Duplicate of", "Confirming <tool>'s finding —".

  ## Three structural patterns (use these explicitly)

  ### 1. The closing rationale (past → present → future)

  ```
  Closing — <past: what this was>. <present: what happened>. <future:
  what comes next instead>.
  ```

  Examples:
  - "Closing — this PR was a CodeQL reproduction probe for INF-1693. The
    probe did its job: alert #4 was filed on the new uses: line, confirming
    the actions/unpinned-tag trigger condition. The fix will land in a
    separate PR."
  - "Closing in favor of a fresh PR. Same branch carries the noise of the
    wrong-pack-name first attempt (commit `c65396c`) and a stale Cursor
    Bugbot annotation against that commit. New PR will land the corrected
    model pack as a single clean commit."
  - "Closing as superseded by PR #22, the most recent Jules-generated
    docs/docs.md PR."

  ### 2. The diagnosis (symptom : root cause — detail)

  ```
  <Symptom>: <root cause> — <specifics, often file:line>. <follow-up sentence
  giving correctness assertion or next step>.
  ```

  Example:
  - "Build fails: stripPort redeclared — defined in both ratelimit.go:176
    and grpc.go:113. The rate-limiting logic itself is correct; a new run
    can fix the duplicate declaration."

  ### 3. The direct review question

  Six to twelve words. No padding. The whole comment is the question.

  Examples:
  - "How was this tested and validated?"
  - "Why this approach over the existing pattern in `<path>`?"
  - "Does this still work when <edge condition>?"

  ## Punctuation habits

  - **Em-dash (—) for elaboration**: "Closing — stale Jules-generated PR."
    The clause after the em-dash may be lowercase if a fragment, capitalized
    if a full sentence.
  - **Colon for diagnosis**: "Build fails: stripPort redeclared".
  - **Semicolon to join correctness assertions**: "The rate-limiting logic
    itself is correct; a new run can fix the duplicate declaration."
  - **Backticks around identifiers**: `c65396c`, `homebrew-lrl`,
    `actions/unpinned-tag`, `models/trusted-owners.model.yml`,
    `ratelimit.go:176`.

  ## Reference conventions

  - PRs as `#NN` for intra-repo; full URL only on the first cross-repo mention.
  - Commits as backticked 7-character SHAs.
  - File paths in backticks, with `:line` suffix when the line number is
    load-bearing.
  - Credit detection tools by name when they flagged something:
    "Confirming Cursor Bugbot's finding", "the codeql alert", "Bugbot
    correctly identified".

  ## What to avoid

  - **Filler / hedging**: "I think", "Maybe", "It would be nice if",
    "Just curious", "In my opinion". Zero of these in real samples.
  - **Apologetic prefacing**: "Sorry to chime in", "Don't mean to nitpick".
  - **Multi-paragraph context-setting**. Lead with the point.
  - **Emojis** in personal critique. (Deploy/release templates like 🐋 or
    `:sunflower:` ARE common in automation-driven messages, but a hand-typed
    code-review comment doesn't carry them.)
  - **Open-ended questions when a specific one will do**. Not "thoughts?" —
    instead "what's the rollback path if Z fails?"

  ## Negative scenarios

  - **WHEN** the agent is about to draft a multi-paragraph comment to "give
    context" before stating a position
  - **THEN** rewrite to lead with the position. Context comes in service of
    the position, in 1-2 follow-up sentences.

  - **WHEN** the comment hedges with "I might be wrong but…" or "Just to
    clarify…"
  - **THEN** delete the hedge entirely. State the observation as fact and
    let the PR author push back if it's wrong.
''
