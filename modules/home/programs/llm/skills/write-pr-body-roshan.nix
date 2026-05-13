''
  # Writing Roshan-style PR descriptions

  Distilled from real hand-authored PR bodies. The user's PR-body
  conventions diverge from GitHub's default in important ways.

  ## ALWAYS check for a repo PR template first

  Before drafting anything, check for an existing template:

  ```bash
  # Repo's PR template lives at one of these canonical paths:
  ls .github/pull_request_template.md \
     .github/PULL_REQUEST_TEMPLATE.md \
     .github/PULL_REQUEST_TEMPLATE/ \
     docs/pull_request_template.md \
     PULL_REQUEST_TEMPLATE.md 2>/dev/null
  ```

  **If a template exists, USE IT VERBATIM as the base.** Do not invent
  additional sections, do not append a Test plan if the template
  doesn't have one, do not add a Risks section if the template doesn't
  ask for one. Fill in the sections the template defines; leave its
  structure alone.

  **If no template exists**, follow the structure below
  (Linear URL → ## Summary → ## Risks or ## Test plan, depending on
  PR type).

  ## How to create the PR

  Use `gh pr create --web` from the CLI. This opens the GitHub web
  editor pre-filled with your body and title, so the user can review,
  add labels/reviewers/assignees, and submit themselves.

  ```bash
  gh pr create --web \\
    --title "<conv-commit-style title>" \\
    --body "<body content>"
  ```

  **NEVER use any of these flags by default:**
  - `--draft` — let the user choose draft vs ready
  - `--fill` / `--fill-first` — auto-fills from commits, bypasses
    the curated body
  - `--reviewer` / `--assignee` / `--label` — let the user pick
  - Submitting without `--web` — the user wants the web review step

  The user's standing rule: prepare the PR but leave the actual
  submission decision (draft vs ready, reviewers, labels) to them.

  ## Top-line: issue URL on its own line

  When the change tracks an external issue (Linear, GitHub issue, etc.),
  the PR body opens with the full URL on the first line, with NOTHING
  preceding it (no "Fixes:", no "Closes:", no header).

  ```
  https://linear.app/laurelai/issue/INF-1693/customize-codeql-policy-for-pinginc-actions

  ## Summary
  ...
  ```

  - The URL is the most important context. Lead with it.
  - "Closes #NN" / "Fixes #NN" Markdown-magic suffixes ARE used, but only
    when the PR fully closes that issue. Otherwise omit them.

  ## Section shape

  Two sections are canonical: `## Summary` and one of `## Risks` /
  `## Test plan`. Pick by PR type:

  - **Config / rollout / refactor / chore**: `## Summary` + `## Risks`.
  - **Bug fix / feature with verifiable behavior**: `## Summary` +
    `## Test plan`.
  - **Probe / spike**: `## Summary` only.

  Other section headers (`## Changes`, `## Run`, `## Pipeline`) appear in
  *automation-generated* PRs only (UNCWORKS, Jules). Hand-authored PRs
  do not use them.

  ## Summary section

  Bulleted list. Each bullet is a complete causal sentence — not a
  fragment. The sentence says **what** changed and **why** in one breath.
  Multiple bullets when there are multiple concerns; a single bullet is
  acceptable for narrow PRs.

  Real exemplars:

  > - The 1.10.0 module rollout (#517) failed to push the codeql model
  >   pack files to `homebrew-lrl` because that repo's branch protection
  >   requires 2 status checks on `main`, which the `github_repository_file`
  >   direct-PUT bypasses. Other repos with the new default-true setting
  >   applied fine — this one's an outlier.
  >
  > - Opting `homebrew-lrl` out via `"enable_codeql_trusted_owners" :
  >   false` until we decide whether to relax its branch protection or
  >   add a CI bypass.

  Note:
  - Bullets are paragraphs in disguise. They can be 2-4 sentences each.
  - **Em-dash for the "this one is the outlier" elaboration**.
  - **Backticked technical identifiers** inline (config keys, module
    versions, file paths). No expansion of acronyms (CodeQL, CI, IAM).
  - **Cross-references**: prior PRs as `#NN` when in the same repo, full
    URL on first reference for cross-repo (`https://github.com/pinginc/infra/pull/2223`).

  ## Risks section

  Bulleted. Each bullet states a specific known limitation or tradeoff,
  not a generic warning. Pair the risk with its mitigation or
  acceptable-cost rationale.

  > - `homebrew-lrl` stays without the trusted-publisher model pack — same
  >   state as before #517 — so `actions/unpinned-tag` will keep firing on
  >   that repo.

  ## Test plan section (when used)

  Markdown checklist with `- [ ]` boxes. Each item is a verification step
  someone else could execute. Avoid "added tests" — that's not a test
  plan, it's a claim. Use the form "verify X by doing Y" or "run Z and
  confirm W".

  ## What to avoid

  - **Generic GitHub PR template defaults** (`## Description`,
    `## Motivation and context`, `## Types of changes` checklists). Roshan's
    real PRs use Summary + Risks/Test plan only.
  - **Preamble** ("This PR adds…", "In this change…"). The summary bullet
    leads with the action, not the meta-frame.
  - **Generated trailers** ("🤖 Generated with Claude Code") unless the PR
    is actually agent-authored end-to-end. When the agent helps and the
    user finalizes, drop the trailer.
  - **Co-authored-by Claude** lines unless the user has explicitly opted
    in for that PR.
  - **Architecture overviews** in PR bodies. Architecture lives in
    `openspec/specs/` and design docs, not PR descriptions.
  - **Emojis** outside automation-template PRs.

  ## Negative scenarios

  - **WHEN** drafting a PR body and tempted to add a "Motivation" or
    "Why" section before the Summary
  - **THEN** fold the motivation INTO the Summary bullets. The "why"
    lives in the same sentence as the "what".

  - **WHEN** the PR has no behavior to test but the GitHub PR template
    asks for a `## Test plan`
  - **THEN** replace it with `## Risks` and list what could regress.

  ## Note on inference

  This skill is v0.1 derived from a small sample (~5 hand-authored PR
  bodies). Refine the rules above when more samples disagree with them.
  When the user pushes back on a draft, that pushback is canonical —
  update the skill, not the rule of thumb.
''
