---
description: 'Writes concise conventional commit messages with agent attribution trailers. Use when drafting or creating commits. Supports ticket prefixes when a tracker ticket is in scope.'
model: haiku
effort: low
---

# Opinionated commit messages

A terse, prescriptive style guide for commit subjects. Each rule pairs the
correct shape with the form it replaces. The defaults describe a single voice;
repo conventions always override.

Provenance: derived from a personal-OSS corpus of 295 PRs and 504 commits, all
authored before 2024-06-01. It also uses the standing rules in
`~/.claude/CLAUDE.md`.

## Decision routing

```
Repo has CONTRIBUTING.md / DCO / a commit format?  -> obey it; the repo wins (see below)
Tracker ticket in active scope?                     -> use the ticket-id variant
No tracker, no repo rules?                           -> <type>(<scope>): <subject>, title-only
Change touches many concerns?                        -> split into multiple commits, one each
```

## First, check the repo's contribution rules

This skill's defaults are the fallback. Before committing in a repo you don't
own, sweep for overrides:

```bash
ls CONTRIBUTING.md .github/CONTRIBUTING.md DCO 2>/dev/null
grep -l "Signed-off-by\\|DCO\\|commit format" \
  CONTRIBUTING.md .github/CONTRIBUTING.md 2>/dev/null
```

- DCO / Signed-off-by required: add `--signoff`; the trailer goes in the body.
- Different mandated format (`[component] message`, `JIRA-123: message`): use it verbatim.
- Issue-link syntax (`Refs #NN`, `Fixes #NN`, `Closes JIRA-XXX`): honor it.
- Co-author conventions: some repos require `Co-authored-by:`, others forbid it.

When a repo has no contribution docs, apply the defaults below unmodified.

## Required shape

```
<type>(<scope>): <subject>
```

- `type` is preferred from: `feat`, `fix`, `refactor`, `chore`, `docs`, `test`,
  `perf`, `build`, `ci`, `revert`. A bare subject with no `type:` is acceptable
  when the change fits no single type (observed in the corpus).
- `scope` is optional: the affected module, lowercase, kebab-case if multi-word.
  In-this-config scopes: `pi`, `llm`, `claude`, `gemini`, `goose`, `codex`,
  `cursor`, `amp`, `opencode`, `openspec`, `hack`, `flake`.
- `subject` is an imperative sentence fragment. No trailing period. Omit explanatory prose by default; retain required trailers.
- Lowercase is preferred (~80% of the corpus). Capitalize only when an identifier
  or proper noun opens the subject; do not force lowercase onto one.

## Subject shape: good vs bad

```
# good — imperative, single clause, scoped, identifiers backticked
feat(claude): auto-allow read-only inspection commands
fix(pi): bump pi-coding-agent to 0.74.0 from earendil-works/pi
refactor(claude): consume harness-kit and canonical allowlist
chore(openspec): archive refresh-pi-stack change

# bad
Feat(claude): Added read-only commands.    # capitalized, past tense, trailing period
fix: bug                                    # vague — name what
chore: misc fixes                           # vague — name what
feat: add allowlist; also bump pi           # two clauses — that is two commits
feat: just a small tweak to the allowlist   # padding words
```

Rationale for the imperative and single-clause rule. The subject completes
"this commit will ___". A second clause means a second logical change, which
belongs in its own commit. Length: prefer under 72 chars, tolerate ~100 when trimming would
lose meaning. Domain abbreviations (sqlite, MCP, OAuth, npm, TUI, CLI) need no
expansion. The `!` after the type marks a breaking change (`feat(auth)!:`).

## Ticket-id prefix inside the subject (standard when a ticket applies)

This is the default whenever a tracker ticket is in scope. It mirrors the
global PR-title convention `<type>(<scope>): <TICKET>: <description>`, so a
squash-merge title stays consistent. In the grounding corpus, 83% of subjects
carried a tracker ticket ID:

```
<type>(<scope>): <PROJECT-NNN>: <subject>   # PROJECT-NNN matches [A-Z]{2,}[0-9]*-[0-9]+
```

The ticket goes **after the scope, before the subject**, never as a trailing
`(TICKET)` suffix. Omit it only for genuinely ad-hoc chores with no ticket.

```
# good, the standard form when a ticket is in scope
fix: OWL-1381: make healthcheck failure threshold configurable
feat(auth)!: OWL-1326: use new permissions token key
TO-291: fixup monitor type for activity/batch alert and elevated 5xx

# bad
fix: PROJ-123: tidy things        # invented ticket id, never fabricate one
```

The conv-commit type may appear with the ticket (`fix: PROJECT-NNN: <subject>`)
or the ticket may stand alone (`PROJECT-NNN: <subject>`). Bare subjects without
a ticket are equally acceptable. The project codes above are historical, not
vocabulary for new work.

## Agent attribution

Include attribution for each agent that contributed to the committed change.
Use its documented `Co-authored-by:` identity when available. Otherwise use
`Assisted-by: <harness>` without inventing an email address or model version.
Include the model when it is known. Keep attribution in trailers after a blank line.

Preserve existing human and agent trailers when amending, cherry-picking, or
squashing. Deduplicate identical trailers. Attribute contributors to this change,
not every installed harness. Do not rewrite pushed history without authorization.

For example, a Codex contribution without a documented co-author identity uses:

```text
fix(cua): check display geometry before actions

Assisted-by: Codex
```

## What to avoid: and what to do instead

- Two-clause subject joined with `;` or em-dash -> split into two commits.
- Multi-paragraph body to explain a big change -> the change is too big; split it.
- Promotional "Generated with..." prose -> use the agent attribution trailers above.
- Inventing a ticket ID when no tracker is in scope -> use a bare or scoped subject.
- Bolded list rows (`- **Foo**: bar`) if a body is written at all -> plain bullets.
- Emojis -> never, anywhere.
