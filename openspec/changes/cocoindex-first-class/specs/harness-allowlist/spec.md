## MODIFIED Requirements

### Requirement: Canonical allowlist tiers

`modules/home/programs/llm/lib/allowlist.nix` MUST expose two pattern lists:
`tierA` (read-only commands safe to auto-allow without prompting; zero
blast radius) and `tierB` (commands that perform reversible local writes —
e.g., `git add`, `nix build`, formatters, `mkdir -p` under known
directories). The lists SHALL be the single source of truth for "what bash
is safe" across all harnesses. `tierA` MUST include the cocoindex
read-only entries `ccc search`, `ccc search *`, and `ccc status`. The
write-side command `ccc index` MUST NOT appear in `tierA` and MUST NOT be
added to `tierB` as part of this change.

#### Scenario: tierA contains the migrated Claude patterns

- **WHEN** the contents of `allowlist.tierA` are inspected after migration
- **THEN** it contains at minimum the 149 patterns previously embedded
  inline in `config/claude.nix` as `tierAReadOnlyBash`
- **AND** it additionally contains `ccc search`, `ccc search *`, and
  `ccc status`

#### Scenario: tierB is non-empty and reversible-only

- **WHEN** `tierB` is inspected
- **THEN** every entry is reversible at the working-tree or build level:
  `git add`, `git restore --staged`, `nix build`, `nh os build` (build
  only, never switch), `nix fmt`, `nixfmt`, `shfmt -w`, `mkdir -p` under
  repo subpaths
- **AND** no entry performs a network write, a system mutation, or a
  destructive operation
- **AND** `ccc index` does not appear in `tierB`

#### Scenario: Write-side cocoindex commands are rejected from tierA

- **WHEN** a contributor attempts to add `ccc index` or `ccc index *` to
  `tierA`
- **THEN** the change MUST be rejected at review because indexing is a
  write operation and `tierA` is read-only by definition
- **AND** the same restriction applies to any future cocoindex subcommand
  whose effect is to mutate the index directory
