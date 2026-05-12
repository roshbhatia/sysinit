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
`cursor.nix` MUST generate at least three rule files: `always.mdc` (general conventions from `AGENTS.md`), `nix.mdc` (Nix-specific style: nixfmt, conventions for module structure), and `markdown.mdc` (rules for `AGENTS.md` / `CLAUDE.md` / `GEMINI.md` editing — referencing the May 2026 standard).

#### Scenario: Three baseline rules materialize
- **WHEN** `nh darwin switch .` completes
- **THEN** `~/.cursor/rules/{always,nix,markdown}.mdc` all exist with their declared frontmatter

### Requirement: Legacy .cursorrules retained during transition
The legacy `~/.cursorrules` (or per-project) file SHALL NOT be deleted by this change. Cursor CLI versions may differ in MDC support; keeping the legacy file ensures continuity until MDC loading is verified working in the user's actual Cursor session. Deletion is reserved for a follow-up.

#### Scenario: Both legacy and MDC present
- **WHEN** both `~/.cursorrules` and `~/.cursor/rules/always.mdc` exist
- **THEN** Cursor loads both without error (newer versions prefer MDC; older versions fall back to `.cursorrules`)

