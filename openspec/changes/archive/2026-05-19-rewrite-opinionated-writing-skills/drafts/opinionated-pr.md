---
name: opinionated-pr
description: Writes GitHub PR descriptions in a terse, opinionated style. Delegates body shape to the repo PR template when one exists; falls back to `## Summary` plus an optional ad-hoc validating-changes block. Never mutates an existing checklist. Use when drafting a `gh pr create` body, opening a PR, or when the user says 'PR body' / 'pull request description'.
---

# Opinionated PR descriptions

An opinionated style guide for GitHub PR bodies. The repo PR template always wins; the defaults below are the fallback when no template exists.

Provenance: derived from a personal-OSS corpus of 295 PRs authored before 2024-06-01, plus the standing rules in `~/.claude/CLAUDE.md`.

## First, read the repo's contribution docs

Before drafting anything, sweep for contribution guidance. Repo-specific rules override the defaults below.

```bash
ls CONTRIBUTING.md CONTRIBUTING.rst CONTRIBUTING \
   .github/CONTRIBUTING.md \
   docs/CONTRIBUTING.md docs/contributing.md \
   2>/dev/null

ls CODE_OF_CONDUCT.md .github/CODE_OF_CONDUCT.md 2>/dev/null
ls .github/CODEOWNERS docs/CODEOWNERS CODEOWNERS 2>/dev/null
ls DCO .github/DCO 2>/dev/null
grep -l "Signed-off-by\\|DCO" CONTRIBUTING.md .github/* 2>/dev/null
ls .github/workflows/ 2>/dev/null
```

Things to extract before drafting:

- Commit format: some repos require `Signed-off-by:` trailers, a specific issue-link syntax (`Refs #NN`, `Fixes JIRA-123`), or prohibit certain types. Use the repo's commit format instead of this skill's default for that repo's PRs.
- Branch naming: some repos require `feature/*`, `fix/*`, `<username>/<topic>`. Check before pushing.
- PR description requirements: some repos require linking an issue (and reject PRs without one), or require a "How to test" section regardless of PR type.
- Test / CI expectations: which checks gate merge; whether docs or CHANGELOG updates are required.
- CODEOWNERS: who will be auto-requested as a reviewer.
- License / DCO: if `Signed-off-by: <name> <email>` is required on every commit, add `--signoff` to `git commit` invocations for that repo.

When a repo's `CONTRIBUTING.md` defines structure that conflicts with the defaults below, the repo wins.

## Always check for a repo PR template first

Before drafting anything, check for an existing template:

```bash
ls .github/pull_request_template.md \
   .github/PULL_REQUEST_TEMPLATE.md \
   .github/PULL_REQUEST_TEMPLATE/ \
   docs/pull_request_template.md \
   PULL_REQUEST_TEMPLATE.md 2>/dev/null
```

If a template exists, USE IT VERBATIM as the base. The template's structure is canonical. Specifically:

- Do not invent additional sections.
- Do not append a Test plan if the template does not have one.
- Do not add a Risks section if the template does not ask for one.
- Do not add new items to any verification or task checklist defined in the template. Only the existing `- [ ]` items may be checked or left unchecked. Appending a fourth checklist item to a template that defines three is forbidden, even when the change introduces a new check that would seem to warrant one.
- Fill the sections the template defines; leave its structure alone.

If no template exists, follow the fallback structure below.

## How to create the PR

Use `gh pr create --web` from the CLI. This opens the GitHub web editor pre-filled with the body and title, so the user can review, add labels and reviewers and assignees, and submit themselves.

```bash
gh pr create --web \
  --title "<conv-commit-style title>" \
  --body "<body content>"
```

Never use any of these flags by default:

- `--draft`: let the user choose draft vs ready.
- `--fill` / `--fill-first`: auto-fills from commits, bypasses the curated body.
- `--reviewer` / `--assignee` / `--label`: let the user pick.
- Submitting without `--web`: the user wants the web review step.

The standing rule: prepare the PR but leave the actual submission decision (draft vs ready, reviewers, labels) to the user. Never auto-submit, draft or ready, unless the immediately preceding user turn explicitly directed it.

## Top-line: issue URL on its own line

When the change tracks an external issue (Linear, JIRA, GitHub issue, etc.), open the PR body with the full URL on the first line, with nothing preceding it. No `Fixes:`, no `Closes:`, no header.

```
https://linear.app/<workspace>/issue/PROJECT-NNN/<slug>

## Summary
...
```

- The URL is the most important context. Lead with it.
- `Closes #NN` / `Fixes #NN` Markdown-magic suffixes are used only when the PR fully closes that issue. Otherwise omit them.

## Fallback structure when no PR template exists

The historical pattern observed in the corpus is `## Summary` plus, when the change has hand-verified behavior to call out, an optional `## Validating Changes (ad-hoc, if logic is not covered by automated tests)` block. That is the canonical fallback.

```
https://linear.app/<workspace>/issue/PROJECT-NNN/<slug>

## Summary

- <one-sentence bullet>
- <one-sentence bullet>

## Validating Changes (ad-hoc, if logic is not covered by automated tests)

- <one-sentence bullet describing what was hand-verified>
```

Notes on the fallback:

- Use `## Summary` and at most `## Validating Changes (ad-hoc, if logic is not covered by automated tests)`. Do not invent other section headings.
- Do not use `## Risks`, `## Test plan`, `## Description`, `## Motivation and context`, `## Types of changes` as fallback sections. Those are either auto-template defaults or post-corpus inventions.

## Summary section

Bulleted list. Each bullet is one sentence describing one concern. Multiple bullets when there are multiple concerns; a single bullet is acceptable for narrow PRs. The shortest acceptable bullet for a truly self-evident PR is `See title.`.

Notes on bullets:

- One sentence per bullet by default. Do not write multi-paragraph bullets.
- Causal connectives are `so`, `as`, `because`. Do not use em-dashes for elaboration.
- Backtick technical identifiers inline: config keys, module versions, file paths.
- No expansion of common acronyms (CodeQL, CI, IAM, MCP).
- Cross-references: prior PRs in the same repo as `#NN`; cross-repo PRs as a bare URL inline.

For long PRs that touch multiple distinct areas, group bullets under area-of-concern subheads with a trailing colon:

```
## Summary

Schema:
- Cleans up types, migrates properties to where it makes the most sense.
- Standardizes return values for queries and mutations.

Permissions:
- Simplifies permissions and adds additional info to README.
- Adds decorators to migrate non-business logic out of resolvers.

Testing:
- Adds e2e tests for all queries and mutations.
- Uses a local OAuth2Server in tests to avoid mocking static resources.
```

This grouped-block shape is preferred over flat multi-sentence bullets when the change spans more than a handful of concerns.

## Validating Changes section

Optional. Use when the PR has behavior that was hand-verified rather than covered by automated tests. The section header is literally `## Validating Changes (ad-hoc, if logic is not covered by automated tests)`. Bullets describe what was actually done, in past tense.

```
## Validating Changes (ad-hoc, if logic is not covered by automated tests)

- Manually triggered the lambda with a sample payload and confirmed the dynamodb row appeared.
```

If the PR has no hand-verified behavior, omit this section entirely. Do not include it as an empty placeholder.

## What to avoid

- Generic GitHub PR template defaults inserted on top of an existing repo template (`## Description`, `## Motivation and context`, `## Types of changes` checklists). Fill the existing template; do not paste a different one over it.
- Preamble (`This PR adds…`, `In this change…`). The summary bullet leads with the action.
- Tool-attribution trailers ("Generated with...", or any robot-emoji-prefixed "Generated with Claude Code" trailer) unless the PR is actually agent-authored end-to-end and the user has opted in.
- `Co-authored-by Claude` lines unless the user has explicitly opted in for that PR.
- Architecture overviews in PR bodies. Architecture lives in `openspec/specs/` and design docs, not PR descriptions.
- Bolded list rows (`- **Foo**: bar`) anywhere in the body. Use plain bullets and backticks for emphasis.
- Multi-sentence bullets in the Summary section. One sentence per bullet by default; use grouped-block shape for breadth.
- Em-dashes for elaboration in prose. Use `so`, `as`, or `because`.
- Adding items to an existing PR template's verification checklist. Only check the existing items; do not append new ones.
- Auto-submitting a PR (draft or ready) without `--web`, unless the user explicitly directed it.
- Emojis, anywhere in the body.

## Negative scenarios

- WHEN drafting a PR body in a repo with a `.github/pull_request_template.md` that defines `## Summary` and `## Checklist` with three `[ ]` items
- THEN the body contains exactly those two headings and exactly those three checklist items. Do not add a fourth.

- WHEN the PR has no behavior to hand-verify but the existing template asks for a verification section
- THEN leave the template's section in place and write `- N/A` or fill the existing checklist accordingly. Do not append a new section.

- WHEN tempted to add a `## Risks` or `## Test plan` section in a repo with no template
- THEN do not. The fallback is `## Summary` plus optional `## Validating Changes (ad-hoc, if logic is not covered by automated tests)`. Risks and Test plan are not part of this skill's fallback structure.

- WHEN the user asks for a "quick PR body" for a one-line change
- THEN write `## Summary\n\n- See title.` and stop. Do not pad.

- WHEN the change spans many areas
- THEN use the grouped-block Summary shape, not a flat list of multi-sentence bullets.

- WHEN about to run `gh pr create` without `--web`
- THEN add `--web`, unless the immediately preceding user turn explicitly said to submit directly.
