''
  # Opinionated PR descriptions

  A prescriptive style guide for GitHub PR bodies. The repo PR template always
  wins; the defaults below are the fallback when none exists. Each rule pairs the
  correct shape with the form it replaces.

  Provenance: derived from a personal-OSS corpus of 295 PRs authored before
  2024-06-01, plus the standing rules in `~/.claude/CLAUDE.md`.

  ## Decision routing

  ```
  Repo has a PR template?                 -> fill it verbatim; add no sections, no checklist items
  No template?                             -> ## Summary + optional ## Validating Changes
  Change tracks an external issue?         -> issue URL alone on line 1, nothing before it
  Behavior hand-verified, not by tests?    -> add the Validating Changes block
  Creating the PR?                          -> gh pr create --web; never auto-submit
  ```

  ## First, read the repo's contribution docs

  Repo-specific rules override these defaults. Sweep before drafting:

  ```bash
  ls CONTRIBUTING.md .github/CONTRIBUTING.md docs/CONTRIBUTING.md 2>/dev/null
  ls .github/CODEOWNERS CODEOWNERS DCO .github/DCO 2>/dev/null
  grep -l "Signed-off-by\\|DCO" CONTRIBUTING.md .github/* 2>/dev/null
  ```

  Extract: required commit format / issue-link syntax, branch naming, whether an
  issue link or a "How to test" section is mandatory, which CI checks gate merge,
  CODEOWNERS reviewers, and DCO/`--signoff` requirements. When `CONTRIBUTING.md`
  conflicts with the defaults below, the repo wins.

  ## Use the repo PR template verbatim when one exists

  ```bash
  ls .github/pull_request_template.md .github/PULL_REQUEST_TEMPLATE.md \
     .github/PULL_REQUEST_TEMPLATE/ docs/pull_request_template.md \
     PULL_REQUEST_TEMPLATE.md 2>/dev/null
  ```

  The template's structure is canonical. Fill its sections; leave its structure alone.

  ```
  # good — template defines ## Summary + a 3-item checklist
  ## Summary
  - <one bullet>
  ## Checklist
  - [x] tests pass
  - [ ] docs updated
  - [ ] changelog entry        (exactly the three the template defines)

  # bad
  ## Summary
  ...
  ## Risks            <- invented section not in the template
  ## Checklist
  - [x] tests pass
  - [ ] docs updated
  - [ ] changelog entry
  - [ ] new: security review   <- appended a fourth checklist item — forbidden
  ```

  Only check or leave the existing `- [ ]` items; never append new ones, even when
  the change seems to warrant one.

  ## How to create the PR — exact form

  ```bash
  gh pr create --web \
    --title "<conv-commit-style title>" \
    --body "<body content>"
  ```

  `--web` opens the pre-filled web editor so the user reviews, sets labels and
  reviewers, and submits. Never use these by default: `--draft`, `--fill` /
  `--fill-first`, `--reviewer` / `--assignee` / `--label`, or submitting without
  `--web`. Never auto-submit (draft or ready) unless the immediately preceding user
  turn explicitly directed it.

  ## Top-line: issue URL alone on line 1

  ```
  # good
  https://linear.app/<workspace>/issue/PROJECT-NNN/<slug>

  ## Summary
  - ...

  # bad
  Fixes: https://linear.app/...    <- no prefix; the bare URL leads
  ```

  Use `Closes #NN` / `Fixes #NN` suffixes only when the PR fully closes that issue.

  ## Fallback structure when no template exists

  ````markdown
  https://linear.app/<workspace>/issue/PROJECT-NNN/<slug>

  ## Summary

  - <one-sentence bullet>
  - <one-sentence bullet>

  ## Validating Changes (ad-hoc, if logic is not covered by automated tests)

  - <one-sentence bullet describing what was hand-verified>
  ````

  Use only `## Summary` and at most `## Validating Changes (ad-hoc, if logic is not
  covered by automated tests)`. Do not invent `## Risks`, `## Test plan`,
  `## Description`, `## Motivation and context`, or `## Types of changes` — those
  are auto-template defaults or post-corpus inventions.

  ## Summary bullets — good vs bad

  ```
  # good — one sentence per bullet, identifiers backticked, causal `so`/`as`/`because`
  - Removes the `incident-io` MCP server as it collides with the company plugin.
  - Gates `networking.hostName` on `!isWork` so MDM can own the work host's name.

  # bad
  - This PR adds a bunch of changes — it removes the server and also...   <- preamble + em-dash + multi-clause
  - **Hostname**: gated on isWork                                          <- bolded list row
  ```

  The shortest acceptable bullet for a self-evident PR is `See title.`. For a PR
  spanning many distinct areas, group bullets under area subheads with a trailing
  colon (`Schema:` / `Permissions:` / `Testing:`) rather than a flat list of
  multi-sentence bullets.

  ## Validating Changes section

  Optional. Use only when behavior was hand-verified rather than covered by tests.
  Header is literally `## Validating Changes (ad-hoc, if logic is not covered by
  automated tests)`. Bullets are past tense, describing what was actually done. If
  nothing was hand-verified, omit the section — do not leave an empty placeholder.

  ## Never

  - Paste a generic GitHub template over an existing repo template.
  - Preamble (`This PR adds…`, `In this change…`) — lead with the action.
  - Tool-attribution / `Co-authored-by Claude` trailers unless the user opted in.
  - Architecture overviews — those live in `openspec/specs/` and design docs.
  - Em-dashes for elaboration — use `so`, `as`, `because`.
  - Emojis, anywhere.
''
