# opinionated-writing-skills Specification

## ADDED Requirements

### Requirement: Three opinionated writing skills exist and are registered

The skill registry at `modules/home/programs/llm/skills/default.nix` MUST contain entries for the three slugs `opinionated-commit`, `opinionated-pr`, and `opinionated-code-comments`. Each entry MUST map to a sibling `.nix` file of the same slug whose `content` import returns the SKILL.md body as a string. The registry MUST NOT contain entries for any of the legacy slugs `write-commit-roshan`, `write-pr-body-roshan`, or `write-issue-roshan`.

#### Scenario: All three opinionated slugs are installed after a switch
- WHEN the user runs `nh os switch` against a tree containing this change
- THEN `~/.claude/skills/opinionated-commit/SKILL.md`, `~/.claude/skills/opinionated-pr/SKILL.md`, and `~/.claude/skills/opinionated-code-comments/SKILL.md` exist as symlinks into the nix store
- AND `~/.claude/skills/write-commit-roshan/SKILL.md`, `~/.claude/skills/write-pr-body-roshan/SKILL.md`, and `~/.claude/skills/write-issue-roshan/SKILL.md` do NOT exist

#### Scenario: A new entry without the matching sibling file fails build
- WHEN `default.nix` references `opinionated-commit` via `import ./opinionated-commit.nix` but the sibling `opinionated-commit.nix` is absent or empty
- THEN `nix flake check` fails at evaluation time with a missing-file or empty-string error before any system mutation occurs

### Requirement: Skill bodies use no proper-noun anchor

The body and description of each of the three skills MUST be free of personal-name references. The string `roshan`, `Roshan`, or any other named individual MUST NOT appear in the SKILL.md body or in the `description` field of the registry entry. Provenance lines that name a historical period or sample (e.g. "derived from a pre-2024 personal-OSS corpus") are allowed when they refer to the corpus, not to a person.

#### Scenario: No personal-name token in the skill body
- WHEN a reviewer searches the rendered SKILL.md body for case-insensitive `roshan`
- THEN there are zero matches across all three skills

#### Scenario: Personal-name token reintroduced
- WHEN a future edit reintroduces a personal-name token into any of the three skill bodies
- THEN the change is rejected at review (this requirement is the gating signal) and the offending token is replaced with a role-neutral phrasing such as "the author" or removed entirely

### Requirement: Commit-subject rules reflect corpus-observed shape

The `opinionated-commit` skill body MUST state that the conventional-commit type prefix (`feat`, `fix`, `chore`, `refactor`, `docs`, `test`, `perf`, `build`, `ci`, `revert`) is preferred but NOT required for every subject; that lowercase is preferred but not absolute; and that the historical `<type>: <TICKET-ID>: <subject>` form (with `TICKET-ID` matching `[A-Z]{2,}[0-9]*-[0-9]+`) is a recognized variant when a tracker ID exists for the work. The body MUST NOT recommend semicolon-joined two-clause subjects, MUST NOT recommend em-dash elaboration in subjects, and MUST NOT state that subjects are universally lowercase.

#### Scenario: Conv-commit prefix recommendation is non-absolute
- WHEN an agent reads the `opinionated-commit` skill body
- THEN it sees the conv-commit prefix described as the dominant shape but is told that bare-ticket-ID titles and unprefixed subjects are also acceptable and observed in historical work

#### Scenario: Banned subject patterns are listed
- WHEN an agent reads the skill body's `## What to avoid` block
- THEN it sees semicolon-joined two-clause subjects and em-dash elaboration listed as banned
- AND the body does not contradict those bans elsewhere

#### Scenario: Author drafts a subject with em-dash elaboration
- WHEN the agent has read the skill and the user asks for a commit subject
- THEN the agent produces a subject that uses `;` and `—` only if the user explicitly overrides the skill, otherwise rewrites to single-clause form

### Requirement: PR-body skill delegates to the repo template

The `opinionated-pr` skill body MUST instruct the agent to detect a repo PR template (`.github/pull_request_template.md` and the other canonical paths) and, when one exists, to fill the template verbatim WITHOUT appending new sections and WITHOUT adding new items to any existing verification or task checklist. Only the existing `- [ ]` items in the template MAY be checked or left unchecked. When no template exists, the skill MUST prescribe a fallback structure consisting of `## Summary` (bulleted, one sentence per bullet) plus an optional `## Validating Changes (ad-hoc, if logic is not covered by automated tests)` section. The skill MUST NOT prescribe `## Risks` or `## Test plan` as the no-template fallback structure.

#### Scenario: Repo PR template exists and is filled verbatim
- WHEN the agent drafts a PR body for a repo whose `.github/pull_request_template.md` defines `## Summary`, `## Checklist` with three `- [ ]` items, and nothing else
- THEN the drafted body contains exactly those two headings and exactly those three checklist items (possibly checked) and no additional sections or list items

#### Scenario: Checklist mutation is rejected
- WHEN the agent drafts a PR body and considers adding a fourth `- [ ]` item to the template's verification checklist
- THEN the agent does NOT add it; the checklist contains only the items defined in the template

#### Scenario: No template, fallback structure used
- WHEN the agent drafts a PR body in a repo with no PR template
- THEN the body uses `## Summary` with one-sentence bullets and optionally `## Validating Changes (ad-hoc, if logic is not covered by automated tests)`, and does NOT use `## Risks` or `## Test plan`

#### Scenario: Long PR uses header-grouped sub-bullets
- WHEN the agent drafts a PR body summarizing more than five distinct concerns
- THEN the body groups bullets under area-of-concern headings (e.g. `Schema:`, `Permissions:`, `Logger:`) rather than as a flat list of multi-sentence bullets

### Requirement: PR-opening flow uses gh pr create --web and never auto-submits

The `opinionated-pr` skill body MUST instruct the agent to use `gh pr create --web` when opening a PR. The skill MUST forbid the use of `--draft`, `--fill`, `--fill-first`, `--reviewer`, `--assignee`, and `--label` as default flags. The skill MUST forbid submitting the PR (draft or ready) without `--web` unless the user has explicitly directed otherwise in the same conversation.

#### Scenario: PR open uses --web
- WHEN the agent runs `gh pr create` on behalf of the user
- THEN the command includes `--web` and excludes `--draft`, `--fill`, `--fill-first`, `--reviewer`, `--assignee`, and `--label`

#### Scenario: Direct submit without explicit user direction
- WHEN the agent considers running `gh pr create` without `--web` (i.e. submitting directly)
- THEN it does NOT, unless the immediately preceding user turn explicitly asked for a direct submit

### Requirement: Source-code-comment skill codifies default-no-comments

The `opinionated-code-comments` skill body MUST state that the default behavior is to write no comment unless the WHY is non-obvious (a hidden constraint, subtle invariant, workaround for a specific bug, or behavior that would surprise a reader). The skill MUST forbid comments that explain WHAT the code does when the identifier already does that, MUST forbid comments that reference the current task or commit, and MUST forbid multi-paragraph docstrings and multi-line comment blocks. Inline comments, when written, are at most one short line. The skill MUST cross-reference the existing `CLAUDE.md` guidance to avoid drift.

#### Scenario: Default is no comment
- WHEN the agent edits a function whose name clearly describes its behavior
- THEN the agent adds no comment, even when the surrounding diff context might suggest one would be welcome

#### Scenario: WHY-only comment is acceptable
- WHEN the agent edits code containing a workaround for a specific upstream bug
- THEN the agent MAY add a one-line comment naming the bug and the reason for the workaround

#### Scenario: Multi-paragraph docstring is rejected
- WHEN the agent considers adding a docstring with multiple paragraphs explaining inputs, outputs, and rationale
- THEN it does NOT; the docstring (if present) is one short line, and rationale belongs in commit/PR prose, not in the source

### Requirement: Cross-cutting anti-patterns are explicitly listed in each skill

Each of the three skills MUST include a `## What to avoid` block listing at minimum: bolded `- **Foo**: bar` list rows in artifact content, emojis anywhere in artifact content, "Generated with..." or "Co-authored-by Claude" trailers unless the user explicitly opts in, and summarizing trailers that restate what the diff already shows. The skill body itself MUST NOT use bolded list rows or emojis (modeling the anti-pattern would undermine the rule).

#### Scenario: Anti-patterns block is present
- WHEN a reviewer reads any of the three SKILL.md bodies
- THEN they see a `## What to avoid` block enumerating at least the four patterns above

#### Scenario: Skill body itself uses no bolded list rows
- WHEN a reviewer greps any of the three SKILL.md bodies for `- \*\*[A-Z]` (bolded list row)
- THEN there are zero matches

#### Scenario: Emoji introduced into a skill body
- WHEN a future edit introduces an emoji character into any of the three skill bodies
- THEN the change is rejected at review and the emoji is removed

### Requirement: Repo-override sweeps are preserved

Each skill body MUST retain a top-section instruction to check for and honor repo contribution conventions before applying the skill's defaults. The list of files to sweep MUST include at minimum `CONTRIBUTING.md`, `.github/CONTRIBUTING.md`, `.github/pull_request_template.md` (for the PR skill), `.github/ISSUE_TEMPLATE/*` (when relevant), and any `Signed-off-by` / DCO indicators. When a repo's conventions conflict with the skill's defaults, the skill MUST defer to the repo.

#### Scenario: Repo with CONTRIBUTING.md requiring sign-off
- WHEN the agent drafts a commit in a repo whose `CONTRIBUTING.md` mandates `Signed-off-by:` trailers
- THEN the agent adds `--signoff` to the `git commit` invocation and accepts that this overrides the skill's default "no commit body" rule

#### Scenario: Repo with no CONTRIBUTING.md
- WHEN the agent operates in a repo with no contribution docs
- THEN the agent applies the skill's defaults without modification

#### Scenario: Repo conventions removed in a future edit
- WHEN a future skill edit deletes the override sweep instruction
- THEN the change is rejected at review (this requirement is the gating signal); the sweep is reinstated

### Requirement: Historical ticket-ID pattern is documented but flagged

The `opinionated-commit` skill body MUST include a section describing the historical `<type>: <TICKET-ID>: <subject>` form using `TICKET-ID` shaped as `[A-Z]{2,}[0-9]*-[0-9]+`. The section MUST be labeled as historical or pre-2024 and MUST state that current work without an active Linear/JIRA tracker does NOT need to carry a ticket prefix. The section MUST use a generic placeholder (e.g. `PROJECT-NNN`) in any documented form-shape examples; concrete Laurel-era project codes (`OWL`, `TO`, `TLS`, `TBP3`, `TBP11`, `PLAT`, `PRS`) MAY appear only in clearly-labeled historical exemplars, not in form-shape recommendations.

#### Scenario: Pattern is documented and flagged historical
- WHEN an agent reads the ticket-ID section of `opinionated-commit`
- THEN it sees the pattern described with a `PROJECT-NNN` placeholder shape and an explicit "historical, not required for current work" qualifier

#### Scenario: Agent over-applies the pattern
- WHEN the agent drafts a commit for current work with no Linear ticket in scope
- THEN the agent does NOT invent a ticket ID and the subject does not contain a `<TYPE>-NNN` token
