# claude-work-plugin-enablement

## ADDED Requirements

### Requirement: Declarative enablement of Claude Code marketplace plugins

The system SHALL provide a `sysinit.llm.claudeCode.enabledPlugins` option that persistently enables named Claude Code marketplace plugins via the user `settings.json`, without requiring per-invocation `--plugin-dir` flags or runtime `/plugin install`.

The option SHALL be a list of `<plugin>@<marketplace>` keys and SHALL default to empty. When non-empty, the system SHALL emit `settings.enabledPlugins` as a map from each key to `true`. When empty, the system SHALL NOT emit the `enabledPlugins` key, leaving `settings.json` byte-identical to its prior form.

#### Scenario: Work host enables laurel-eng globally

- **WHEN** the work host config sets `llm.claudeCode.enabledPlugins = [ "laurel-eng@Laurel" ]` and `marketplaces.Laurel` to the local clone path, and `nh darwin switch` is applied
- **THEN** the rendered `~/.claude/settings.json` contains `"enabledPlugins": { "laurel-eng@Laurel": true }`
- **AND** launching `claude` in any repository on the work host loads `laurel-eng` with no `--plugin-dir` flag

#### Scenario: Personal host is unaffected

- **WHEN** a host does not set `llm.claudeCode.enabledPlugins` (the default empty list)
- **THEN** the rendered `settings.json` contains no `enabledPlugins` key
- **AND** the output is identical to the configuration produced before this option existed

### Requirement: Work marketplace registered as a private directory source

The system SHALL register the work marketplace as a directory source pointing at a locally maintained clone, supplied as a string path so the clone is never copied into the Nix store nor leaked into the public configuration.

#### Scenario: Laurel marketplace resolves to the local work clone

- **WHEN** the work host sets `llm.claudeCode.marketplaces.Laurel = "github/work/pinginc/ai-tooling"`
- **THEN** `~/.claude/plugins/known_marketplaces.json` registers `Laurel` with `source = "directory"` and `path` resolved to `$HOME/github/work/pinginc/ai-tooling`
- **AND** no work repository path is present in the Nix store or the public repository

#### Scenario: Marketplace updates remain operator-driven

- **WHEN** the upstream marketplace repository advances
- **THEN** the registered directory source reflects whatever is checked out in the local clone
- **AND** refreshing it is the operator's responsibility (e.g. `git pull` in the clone); the CLI does not auto-refresh a directory source
