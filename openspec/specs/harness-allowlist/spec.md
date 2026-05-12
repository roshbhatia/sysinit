# harness-allowlist Specification

## Purpose
TBD - created by archiving change dry-llm-harnesses. Update Purpose after archive.
## Requirements
### Requirement: Canonical allowlist tiers
`modules/home/programs/llm/lib/allowlist.nix` MUST expose two pattern lists: `tierA` (read-only commands safe to auto-allow without prompting; zero blast radius) and `tierB` (commands that perform reversible local writes — e.g., `git add`, `nix build`, formatters, `mkdir -p` under known directories). The lists SHALL be the single source of truth for "what bash is safe" across all harnesses.

#### Scenario: tierA contains the migrated Claude patterns
- **WHEN** the contents of `allowlist.tierA` are inspected after migration
- **THEN** it contains at minimum the 149 patterns previously embedded inline in `config/claude.nix` as `tierAReadOnlyBash`

#### Scenario: tierB is non-empty and reversible-only
- **WHEN** `tierB` is inspected
- **THEN** every entry is reversible at the working-tree or build level: `git add`, `git restore --staged`, `nix build`, `nh os build` (build only, never switch), `nix fmt`, `nixfmt`, `shfmt -w`, `mkdir -p` under repo subpaths
- **AND** no entry performs a network write, a system mutation, or a destructive operation

### Requirement: One formatter per harness consuming the allowlist
The allowlist MUST expose `formatFor<Harness>` for each harness whose native config can express a bash-allowlist: `formatForClaude` (returns `["Bash(<pattern>)" ...]`), `formatForOpencode` (returns the per-tool `bash.<key> = "allow"` attrset), `formatForGoose` (uses the existing `mcp.nix` formatter shape), `formatForAmp` (returns the `tool×match×action` triples), `formatForCrush` (returns the `allowed_tools` list), `formatForCursor` (returns `["Shell(<pattern>)" ...]`).

Harnesses that do not have a native bash-allowlist concept (`aider`, `codex`, `copilot-cli`, `gemini`) SHALL NOT consume `allowlist`. Their configs MUST NOT reference it.

#### Scenario: Claude formatter output shape
- **WHEN** `allowlist.formatForClaude allowlist.tierA` is evaluated
- **THEN** the result is a list of strings each matching the pattern `Bash(<pattern>)` and the length is exactly `builtins.length allowlist.tierA`

#### Scenario: Opencode formatter output shape
- **WHEN** `allowlist.formatForOpencode (allowlist.tierA ++ allowlist.tierB)` is evaluated
- **THEN** the result is an attrset with one key per tool the harness recognizes, each value `"allow"`, and the attrset is non-empty

#### Scenario: Cross-harness consistency
- **WHEN** the rendered Claude `settings.json` allow-list and the rendered opencode `permission.bash` attrset are both derived from the same `allowlist.tierA` source
- **THEN** every command auto-allowed in Claude is also auto-allowed in opencode (modulo Harness-specific syntactic differences)

### Requirement: Claude allowlist is sourced from the canonical list
`modules/home/programs/llm/config/claude.nix` MUST construct its `permissions.allow` list as `allowlist.formatForClaude allowlist.tierA`. The inline `tierAReadOnlyBash` list previously in `claude.nix` SHALL be removed.

#### Scenario: Inline list removed
- **WHEN** `claude.nix` is read after the refactor
- **THEN** the string `"tierAReadOnlyBash"` does not appear in the file
- **AND** the `permissions.allow` value is `allowlist.formatForClaude allowlist.tierA` (or equivalent destructured form)

#### Scenario: Byte-identity preserved
- **WHEN** the rendered `~/.claude/settings.json` is compared before and after the refactor
- **THEN** `diff` reports no differences in the `permissions.allow` array contents (order may differ; multiset equality is sufficient)

### Requirement: New patterns added via the canonical list only
Adding a new auto-allowed pattern MUST be done by editing `lib/allowlist.nix`. Adding a pattern directly to any harness config (e.g., editing `claude.nix`'s consumer of `formatForClaude` to append a literal `"Bash(...)"` entry) SHALL be considered a style violation.

#### Scenario: New pattern added via the canonical list
- **WHEN** a contributor appends `"gh status*"` to `allowlist.tierA` and runs `nh darwin switch .`
- **THEN** the rendered Claude allowlist, the opencode `bash.gh*` attrset (if it covers `gh`), and any other consuming harness all pick up the new pattern simultaneously

#### Scenario: Per-harness pattern bypass
- **WHEN** a contributor edits `claude.nix` to add `++ [ "Bash(some-cmd)" ]` after the `formatForClaude` call
- **THEN** the inline addition is flagged by code review (no automated check enforces it; this is a discipline-level constraint)

