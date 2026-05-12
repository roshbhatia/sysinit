## ADDED Requirements

### Requirement: Gemini extensions are vendored under .gemini/extensions/
Extensions for the Gemini CLI MUST be installed at `~/.gemini/extensions/<name>/` via `home.file` entries generated from `modules/home/programs/llm/config/gemini.nix`. The set of installed extensions SHALL be declared as an attrset in `gemini.nix` analogous to the `piPackages` attrset in `pi.nix`, with at least one entry: `openspec-awareness`.

#### Scenario: Extension materializes on activation
- **WHEN** `nh darwin switch .` completes after this change
- **THEN** `~/.gemini/extensions/openspec-awareness/` exists with the extension manifest and prompt file

#### Scenario: Empty extension set
- **WHEN** the extension attrset in `gemini.nix` is set to `{ }` and rebuilt
- **THEN** `~/.gemini/extensions/` may exist as an empty directory but contains no extension subdirectories

### Requirement: openspec-awareness extension reads active change state
The `openspec-awareness` extension MUST shell out to `openspec list --json` on session start (where Gemini's extension system supports startup hooks) or via a documented prompt-injection mechanism, and surface the active openspec change name in the conversation context. Failure to reach `openspec` SHALL be silent (the extension produces no error and contributes no context line) rather than fatal.

#### Scenario: Active change present
- **WHEN** an openspec change is active and Gemini's extension fires its startup hook
- **THEN** the conversation context includes a line of the form `Active openspec change: <name>` or equivalent

#### Scenario: openspec unavailable
- **WHEN** the `openspec` CLI is not on PATH at session start
- **THEN** the extension does not inject any context and does not raise an error

### Requirement: Extension manifest shape is documented
Each extension subdirectory under `~/.gemini/extensions/<name>/` MUST contain at minimum a `gemini-extension.json` manifest declaring the extension's `name`, `version`, and `mcpServers` (which may be empty) per Gemini CLI's documented schema. The `version` field is owned by sysinit (semver), not by an upstream npm publish.

#### Scenario: Manifest fields present
- **WHEN** `~/.gemini/extensions/openspec-awareness/gemini-extension.json` is parsed
- **THEN** the JSON has top-level keys `name`, `version`, and `mcpServers`
- **AND** `name` equals `"openspec-awareness"`, `version` is a semver string, `mcpServers` is an object (possibly empty)

#### Scenario: Manifest missing required field
- **WHEN** a contributor edits `gemini.nix` to omit the `version` from an extension's manifest
- **THEN** a build-time assertion in `gemini.nix` fails citing the missing required field
