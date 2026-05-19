# Rewrite opinionated writing skills

## Why

The three `write-{commit,pr-body,issue}-roshan` skills self-describe as v0.1 derived from a small (~5 PR) sample of AI-era hand-authored work in this repo. A corpus of 295 PRs, 504 commits, and matching per-PR comments authored in `github.com/pinginc` before 2024-06-01 (the pre-LLM-coupled era) contradicts the current rules on multiple load-bearing axes: title shape, lowercase strictness, body section structure, bullet length, and causal connectives. The skills are also named after a person, which makes the LLM read them as impersonation rather than as a style guide, and the issue skill in particular gets little use. A separate, recurring problem is that no skill captures the user's stance on inline source-code comments, so the agent drifts toward decorative or LLM-shaped comments unless reminded.

## What Changes

- Rename and de-personalize the two existing commit-and-PR skills into `opinionated-commit` and `opinionated-pr`. No "Roshan" in description or body; the skills read as a generic opinionated style guide.
- Add a new skill `opinionated-code-comments` that codifies the no-comments-by-default stance from `CLAUDE.md` plus the terse, lowercase-preferred voice observed in the corpus prose, applied to inline source comments.
- Remove the `write-issue-roshan` skill entirely. The user does not open issues frequently enough to warrant a dedicated skill; ad-hoc judgement is sufficient.
- Rewrite the bodies of `opinionated-commit` and `opinionated-pr` from scratch against the Laurel-era corpus, correcting at minimum these v0.1 errors:
  - Title shape: allow `<type>: <TICKET-ID>: <subject>` as a recognized historical form, with conv-commit prefix being preferred but not required.
  - "Lowercase throughout" softens to "lowercase preferred" — corpus shows ~80% lowercase, not absolute.
  - Two-clause semicolon-joined subjects and em-dash elaboration are removed as exemplars — zero occurrences in the corpus.
  - PR body structure delegates entirely to the repo PR template when one exists. The skill MUST NOT add items to the template's verification checklist, only fill the existing `[ ]` items. The no-template fallback is `## Summary` (bulleted, one sentence per bullet) plus an optional `## Validating Changes (ad-hoc, if logic is not covered by automated tests)`. The current skill's `## Risks` and `## Test plan` sections are removed as fallback structure.
  - Causal connectives in prose use `so`, `as`, `because`, not em-dashes.
  - Long PR bodies use header-grouped bullet blocks (`Schema:`, `Permissions:`, ...) rather than flat 2-4-sentence bullets.
- Add explicit anti-patterns observed in LLM-generated output that the corpus never exhibits: bolded `- **Foo**: bar` list rows, emojis anywhere, mutating an existing PR template's checklist by appending items, summarizing trailers, and "Generated with..." attribution lines.
- Codify PR-opening flow as `gh pr create --web` only — no `--draft` / `--fill` / `--reviewer` flags by default, and never auto-submit (draft or ready) unless the user explicitly directs it.
- Keep the existing repo-override sweeps (CONTRIBUTING.md detection, PR template detection, DCO sign-off handling). They are orthogonal to voice and remain useful in non-pinginc repos.

### Non-goals

- Rewriting any other skill (`cocoindex-query`, `openspec-*`, `seshy`, `shell-scripting`, `find-skills`, `agent-skill-authoring`, etc.).
- Adding a skill for issue bodies. The old `write-issue-roshan` is deleted with no replacement.
- Adding a skill for PR review comments or reply comments. The conversational register is left to ad-hoc judgement.
- Adding new fields to repo PR templates or modifying templates in foreign repos.
- Mutating any existing repo PR template's verification checklist. The skill MUST only fill the existing `[ ]` items.
- Retroactively replaying old commits or PR bodies through the new skills.
- Adding ticket-ID enforcement for current work. The `<type>: <TICKET-ID>: <subject>` form is documented as historically dominant, not required; current Linear-or-no-tracker workflows do not need to carry a ticket prefix.
- Hardcoding the corpus's Laurel-era ticket-project codes (`OWL`, `TO`, `TLS`, ...) as a required vocabulary. They appear in historical examples but are not vocabulary for future work.
- Pulling a source-code-comment corpus from the pinginc repos. The `opinionated-code-comments` skill is derived from `CLAUDE.md`'s existing "default to no comments" stance plus the corpus prose voice, not from a separate code-comment corpus.

## Capabilities

### New Capabilities

- `opinionated-writing-skills`: defines the three artifact-shaped style skills (`opinionated-commit`, `opinionated-pr`, `opinionated-code-comments`), the rules each must satisfy, and the cross-cutting anti-patterns each must reject.

### Modified Capabilities

None. The `agent-skill-library` spec governs registry shape and installation rules, not the specific inventory of entries. Removing three entries and adding three entries is a pure implementation change captured in `tasks.md`, not a spec-level modification.

## Impact

- `modules/home/programs/llm/skills/`: three new `opinionated-*.nix` files, three old `write-*-roshan.nix` files deleted, `default.nix` import map updated.
- `CLAUDE.md`: the `## Skills` list block names the old skills; update to the new ones.
- `AGENTS.md`: scan for any old-name references and update.
- `.sysinit/laurel-corpus/`: already populated as scratch material for the rewrite; not tracked, not part of the change.
- Impactful action: `nh os switch` regenerates the `~/.claude/skills/` symlinks. The three old skill directories will be removed and three new ones created. Until `nh os switch` runs, the agent still sees the old skill names. `nh os build` is the verify step before `nh os switch`.
- Impactful action: skill rename and removal breaks any in-flight conversation or stored hint that references the old skill slugs. No persistent state stores these references, so the blast radius is contained to muscle memory.
- This change is progressive-rollout-shaped: the three skills can be authored and reviewed independently (different artifact types, different rule sets), then the rename + delete + registry update lands as a single atomic switch since the three entries must be registered together for the `default.nix` import to compile.
