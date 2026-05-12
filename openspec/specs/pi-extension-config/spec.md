# pi-extension-config Specification

## Purpose
TBD - created by archiving change refresh-pi-stack. Update Purpose after archive.
## Requirements
### Requirement: Per-extension config is generated, not hand-edited
Configuration files at `~/.pi/agent/extensions/<name>/config.json` MUST be generated from `pi.nix` via `home.file` entries. Hand-edited config files at these paths SHALL be overwritten on activation. The home-manager activation script merges `pi.nix`-managed settings into `~/.pi/agent/settings.json` while preserving keys pi writes at runtime (session data, etc.).

#### Scenario: Activation overwrites a hand-edit
- **WHEN** a user manually edits `~/.pi/agent/extensions/pi-tool-display/config.json` and then runs `nh darwin switch .`
- **THEN** the activation step replaces the file with the Nix-generated version
- **AND** the activation log reports the file was replaced

#### Scenario: Runtime-written settings.json keys survive activation
- **WHEN** pi writes a session-state key into `~/.pi/agent/settings.json` and the user runs `nh darwin switch .`
- **THEN** that key is preserved while Nix-managed keys (`packages`, `quietStartup`, `showLastPrompt`) are merged in

### Requirement: Permission enforcement is single-source
At most one permission-gating extension SHALL be active in the vendored extension list at any time. When `@gotgenes/pi-permission-system` is in the package list, the legacy `confirm-destructive` TypeScript extension MUST NOT be vendored. The two cannot both intercept tool calls without conflict.

#### Scenario: Permission-system is active
- **WHEN** `@gotgenes/pi-permission-system` appears in the package list
- **THEN** `confirm-destructive.ts` is absent from `~/.pi/agent/extensions/` and absent from the upstream-extensions vendor list in `pi.nix`

#### Scenario: Both gates accidentally enabled
- **WHEN** a contributor adds `@gotgenes/pi-permission-system` but forgets to remove `confirm-destructive` from the vendored extension list
- **THEN** `nix flake check` (or a build-time assertion in `pi.nix`) fails citing the conflict

### Requirement: Load-order constraints documented and enforced
Extensions with peer dependencies or interception responsibilities MUST be loaded in a specific order: permission-system FIRST (wraps all tool calls), then provider-routing extensions (`@benvargas/*`), then orchestration extensions (`pi-subagents`, `taskplane`), then UI/memory/advisor extensions, then the custom `openspec-status` extension last. The order MUST be expressed by the array order of the `packages` field in the rendered `settings.json`.

#### Scenario: Permission-system loads before tool providers
- **WHEN** the rendered `~/.pi/agent/settings.json` is inspected
- **THEN** the index of `@gotgenes/pi-permission-system` is less than the index of every tool-providing package (`pi-tool-display`, `@heyhuynhgiabuu/pi-diff`, `pi-dcp`, `pi-webfetch-to-markdown`, `pi-mcp-adapter`)

#### Scenario: Out-of-order configuration
- **WHEN** a contributor edits `pi.nix` and places `pi-tool-display` before `@gotgenes/pi-permission-system` in the package list
- **THEN** `nix flake check` (or a Nix-level assertion) fails with a message naming the misordered packages

### Requirement: Provider-coupled extensions are documented
The provider-coupled extensions (`@benvargas/pi-claude-code-use` for Anthropic; `@benvargas/pi-openai-fast`, `@benvargas/pi-openai-verbosity` for OpenAI/Codex) MUST be installed unconditionally but documented in `pi.nix` comments with a one-line note on which provider each affects. A future change MAY add per-host conditional installation; this change SHALL NOT.

#### Scenario: Provider-coupled extensions are commented
- **WHEN** the relevant block of `pi.nix` is read
- **THEN** each provider-coupled extension has an inline comment naming its provider

### Requirement: Upstream extension list excludes confirm-destructive
The `extensions` list in `pi.nix` that fetches `.ts` files from the upstream repository MUST NOT include `confirm-destructive` (replaced by `@gotgenes/pi-permission-system`). The other 14 currently-vendored extensions MAY remain.

#### Scenario: Extension list is correct
- **WHEN** the `extensions` Nix list in `pi.nix` is inspected
- **THEN** it contains `dirty-repo-guard`, `git-checkpoint`, `handoff`, `input-transform`, `interactive-shell`, `mac-system-theme`, `model-status`, `notify`, `preset`, `reload-runtime`, `session-name`, `status-line`, `tools`, `trigger-compact` and does NOT contain `confirm-destructive`

