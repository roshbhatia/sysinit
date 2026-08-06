# pi-extension-config Specification

## Purpose
TBD - created by archiving change refresh-pi-stack. Update Purpose after archive.
## Requirements
### Requirement: Per-extension config is generated, not hand-edited

Configuration files at `~/.pi/agent/extensions/<name>/config.json` MUST be
generated from `pi.nix` via `home.file` entries. Hand-edited config files at
these paths SHALL be overwritten on activation.

The home-manager activation script merges the `pi.nix` settings into
`~/.pi/agent/settings.json`. A key that `pi.nix` declares MUST win over a value
pi wrote at runtime. A key that `pi.nix` does not declare MUST be preserved,
because pi stores session bookkeeping there.

`pi.nix` MUST NOT declare a settings key that the installed pi build does not
recognize. A key absent from the installed build is dead configuration and
misreports the harness as configured.

Undeclaring a key MUST remove it from the live file. The activation merge is a
deep merge, so a key already written to disk survives every later activation
once Nix stops declaring it. The activation script MUST therefore carry an
explicit retired-key list and delete those keys before it merges. Without that
list, removing a key from `pi.nix` is a no-op against the running harness.

The declared key set MUST cover every setting this repository has an opinion
about, including the selected theme, so an owner-set runtime value cannot
silently replace the generated one.

#### Scenario: Activation overwrites a hand-edit

- **POLARITY** positive
- **WHEN** a user manually edits
  `~/.pi/agent/extensions/pi-tool-display/config.json` and then runs
  `nh darwin switch`
- **THEN** the activation step replaces the file with the Nix-generated version
- **AND** the activation log reports the file was replaced

#### Scenario: A Nix-declared key wins over a runtime value

- **POLARITY** positive
- **WHEN** pi writes a value at runtime for a key `pi.nix` declares, and the
  owner then runs `nh darwin switch`
- **THEN** the merged file carries the Nix value

#### Scenario: Runtime-written settings.json keys survive activation

- **POLARITY** positive
- **WHEN** pi writes a key that `pi.nix` does not declare and the owner runs
  `nh darwin switch`
- **THEN** that key is preserved

#### Scenario: A retired key leaves the live file

- **POLARITY** positive
- **WHEN** a key is added to the retired-key list and the owner runs
  `nh darwin switch`
- **THEN** the activation deletes that key from `~/.pi/agent/settings.json`
- **AND** a later activation does not reintroduce it

#### Scenario: Undeclaring a key without retiring it is caught

- **POLARITY** negative
- **WHEN** a key is removed from the declared set and is not added to the
  retired-key list
- **THEN** the build fails and names the key
- **AND** the message states that a deep merge cannot remove it

#### Scenario: A key the installed build does not recognize fails the build

- **POLARITY** negative
- **WHEN** `pi.nix` declares a settings key that does not appear in the
  installed pi build
- **THEN** the build fails and names the key
- **AND** the configuration does not reach the live machine

#### Scenario: A generated theme that is never selected fails the build

- **POLARITY** negative
- **WHEN** `pi.nix` generates a theme file and declares no setting selecting it
- **THEN** the build fails and names the unselected theme

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

