# cursor-rules-mdc Specification

## Purpose
TBD - created by archiving change optimize-llm-harnesses. Update Purpose after archive.
## Requirements
### Requirement: Cursor rules live under .cursor/rules/ as MDC files
Cursor rule files MUST be installed at `~/.cursor/rules/<name>.mdc` (or per-project at `.cursor/rules/<name>.mdc`) via `home.file` entries generated from `cursor.nix`. Each MDC file SHALL contain a frontmatter block declaring at minimum `description` and either `alwaysApply: true` OR a `globs:` list, but not both.

#### Scenario: Always-apply rule present
- **WHEN** `~/.cursor/rules/always.mdc` is inspected
- **THEN** its frontmatter contains `alwaysApply: true` and no `globs:` entry

#### Scenario: Glob-scoped rule present
- **WHEN** `~/.cursor/rules/nix.mdc` is inspected
- **THEN** its frontmatter contains `globs:` with at least `**/*.nix` and does NOT contain `alwaysApply: true`

#### Scenario: Both keys set is rejected
- **WHEN** an MDC frontmatter sets both `alwaysApply: true` and `globs: [...]`
- **THEN** the rendered file fails Cursor's loader (silent skip) and a Nix-side assertion in `cursor.nix` flags the conflict at build time

### Requirement: Canonical rule set

`cursor.nix` MUST generate at least three rule files: `always.mdc`, `nix.mdc`,
and `markdown.mdc`.

The body of `always.mdc` MUST be generated from `instructions.nix`, not
authored by hand. Only its MDC frontmatter is authored, because the frontmatter
is a Cursor loader concern and not a rule.

`nix.mdc` and `markdown.mdc` MAY stay authored, because they carry
glob-scoped domain rules that the shared cross-repository context deliberately
excludes.

No rule file SHALL restate a version number, a command, or a prohibition that
`instructions.nix` already renders. Restating one creates a second place to
drift, which is the failure this requirement exists to prevent.

Both authored files violate that rule today. `markdown.mdc` restates the
section order, the line cap, `openspec 1.3.0`, and the prohibitions, and
`nix.mdc` carries its own Prohibitions section. They MUST be stripped of those
restatements before the assertion is added, or the assertion fails the build on
files this capability declares authored.

#### Scenario: Three baseline rules materialize

- **POLARITY** positive
- **WHEN** `nh darwin switch` completes
- **THEN** `~/.cursor/rules/{always,nix,markdown}.mdc` all exist with their
  declared frontmatter

#### Scenario: The always rule tracks the generator

- **POLARITY** positive
- **WHEN** a prohibition is added to `instructions.nix`
- **THEN** the rendered `always.mdc` carries that prohibition with no edit to
  the cursor module

#### Scenario: A hand-written restatement fails the build

- **POLARITY** negative
- **WHEN** an authored rule file restates a prohibition or a pinned version
  that `instructions.nix` already renders
- **THEN** the build fails and names the duplicated line

#### Scenario: The existing restatements are stripped first

- **POLARITY** negative
- **WHEN** the assertion is added while `markdown.mdc` still names
  `openspec 1.3.0` and `nix.mdc` still carries a Prohibitions section
- **THEN** the build fails on both files
- **AND** the assertion is not added before those restatements are removed

#### Scenario: A pinned version in a rule file is rejected

- **POLARITY** negative
- **WHEN** an authored rule file names a pinned tool version
- **THEN** the build fails and names the line
- **AND** the message directs the author to the repository's own `AGENTS.md`,
  which is where a repository fact belongs

### Requirement: Legacy .cursorrules retained during transition
The legacy `~/.cursorrules` (or per-project) file SHALL NOT be deleted by this change. Cursor CLI versions may differ in MDC support; keeping the legacy file ensures continuity until MDC loading is verified working in the user's actual Cursor session. Deletion is reserved for a follow-up.

#### Scenario: Both legacy and MDC present
- **WHEN** both `~/.cursorrules` and `~/.cursor/rules/always.mdc` exist
- **THEN** Cursor loads both without error (newer versions prefer MDC; older versions fall back to `.cursorrules`)

