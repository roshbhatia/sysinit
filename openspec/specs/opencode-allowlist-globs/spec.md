# opencode-allowlist-globs Specification

## Purpose
TBD - created by archiving change optimize-llm-harnesses. Update Purpose after archive.
## Requirements
### Requirement: Opencode bash allowlist uses glob patterns
The `permission.bash` block in the rendered `~/.config/opencode/opencode.json` MUST express auto-allow rules as glob patterns where opencode's matcher supports them. Per-subcommand explicit entries (`"git status*"`, `"git diff*"`, …) SHALL be collapsed into broader globs (`"git:*"`) when the broader pattern's semantics match the union of the per-subcommand entries.

#### Scenario: Compacted git allowlist
- **WHEN** the rendered allowlist is inspected
- **THEN** there is a single `"git:*" = "allow"` (or equivalent) entry instead of 18+ per-subcommand `git status*` / `git diff*` / `git log*` / … entries
- **AND** the rendered file's auto-allow surface (set of commands that would be auto-allowed) is a superset of the pre-compaction surface

#### Scenario: Compaction preserves "ask" rules
- **WHEN** a command was previously `ask` (e.g., `git commit*`, `git push*`, `rm*`)
- **THEN** the compacted rule set still classifies that command as `ask`, even if a broader glob would have matched it
- **AND** the `ask` rules take precedence over `allow` rules at opencode's matcher level (consumer responsibility, not formatter)

### Requirement: Compaction logic lives in lib/allowlist.nix
The glob-based formatter for opencode MUST live in `modules/home/programs/llm/lib/allowlist.nix` (extending the existing `formatForOpencode`) so the canonical allowlist remains the single source of truth. Inline `permission.bash` blocks in `opencode.nix` SHALL NOT exceed ~20 lines after this change (the kept-inline content is opencode-specific policy: `ask` overrides, deny rules).

#### Scenario: opencode.nix is slim after compaction
- **WHEN** the line count of `config/opencode.nix` is checked
- **THEN** it is no more than 60% of its pre-compaction line count (was ~520; target ≤ 320)

#### Scenario: Future allowlist additions
- **WHEN** a contributor wants to add a new auto-allowed command pattern to opencode
- **THEN** they add it to `lib/allowlist.nix`'s `tierA` or `tierB` (and update the canonical formatter if a new glob class is needed), NOT to `opencode.nix`

