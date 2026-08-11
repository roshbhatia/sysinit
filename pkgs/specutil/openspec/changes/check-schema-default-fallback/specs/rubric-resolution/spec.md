## ADDED Requirements

### Requirement: Rubric resolution follows a stated precedence ladder

specutil SHALL resolve the governing rubric in a fixed order: an explicit `check:` block in `openspec/specutil.yaml`, then the `schema:` key in `openspec/config.yaml`, then the schema the openspec CLI resolves as its default. The first rung that yields a name with a known preset wins. specutil SHALL NOT consult a later rung once an earlier one resolves.

#### Scenario: Explicit check block wins over every fallback
- **POLARITY** positive
- **WHEN** `openspec/specutil.yaml` declares a `check:` block and `openspec/config.yaml` names a different schema
- **THEN** specutil enforces the rules in the `check:` block
- **AND** specutil does not read the openspec CLI default

#### Scenario: Config schema wins over the CLI default
- **POLARITY** positive
- **WHEN** `openspec/config.yaml` declares `schema: spec-driven` and the openspec CLI default is `rosh-spec-driven`
- **THEN** specutil resolves `spec-driven`
- **AND** specutil enforces nothing, because no preset is registered for that name

#### Scenario: Config file is absent
- **POLARITY** positive
- **WHEN** no `openspec/specutil.yaml` and no `openspec/config.yaml` exist, and the openspec CLI default is `rosh-spec-driven`
- **THEN** specutil resolves `rosh-spec-driven` and enforces its preset

#### Scenario: Config file exists but omits the schema key
- **POLARITY** positive
- **WHEN** `openspec/config.yaml` exists and contains only a `context:` block
- **THEN** specutil resolves the openspec CLI default and enforces its preset

#### Scenario: Config file is unreadable or malformed
- **POLARITY** negative
- **WHEN** `openspec/config.yaml` exists but is not valid YAML
- **THEN** specutil reports the parse failure on stderr and enforces nothing for that repository
- **AND** specutil does not silently fall through to the CLI default, because a corrupt config is an author error, not an absent declaration

### Requirement: The CLI default is read from the openspec installation

specutil SHALL obtain the fallback schema name from the installed openspec CLI at resolution time. specutil SHALL NOT compile a default schema name into its own source. When the openspec CLI is absent, unreadable, or does not report a default, specutil SHALL treat the fallback rung as yielding no name.

#### Scenario: Patched CLI default is honoured
- **POLARITY** positive
- **WHEN** the installed openspec CLI reports `rosh-spec-driven` as its default and no config names a schema
- **THEN** specutil resolves `rosh-spec-driven`

#### Scenario: openspec CLI is not installed
- **POLARITY** negative
- **WHEN** no `openspec` executable is on PATH and no config names a schema
- **THEN** specutil enforces nothing and prints the existing `no rubric declared` message
- **AND** specutil exits 0, because an absent optional dependency is not a rule violation

#### Scenario: openspec CLI reports an unknown schema name
- **POLARITY** negative
- **WHEN** the CLI default names a schema for which specutil ships no preset
- **THEN** specutil enforces nothing and names the unresolved schema in the `no rubric declared` message

### Requirement: The resolution source is reported to the author

`specutil check --list-rules` SHALL name which rung supplied the rubric: the `check:` block, `openspec/config.yaml`, or the openspec CLI default. The report SHALL name the resolved schema when a schema supplied it.

#### Scenario: Source is named for a CLI-default resolution
- **POLARITY** positive
- **WHEN** the author runs `specutil check --list-rules` in a repository with no config file
- **THEN** the output states that the rubric came from the openspec CLI default and names the schema

#### Scenario: Source is requested when nothing resolves
- **POLARITY** negative
- **WHEN** the author runs `specutil check --list-rules` and no rung yields a known preset
- **THEN** the output lists no rules and states which rungs were tried and what each yielded
- **AND** the command exits 0 rather than reporting an empty rubric as an error

### Requirement: Extraction shares the resolution ladder

`ExtractConfig` SHALL use the same resolved schema name as `CheckConfig`. A repository SHALL NOT resolve one schema for checking and a different schema for extraction.

#### Scenario: Extraction inherits the CLI default
- **POLARITY** positive
- **WHEN** a repository has no `schema:` key and the CLI default names a schema with both a check preset and an extract preset
- **THEN** both `specutil check` and extraction use that schema

#### Scenario: Schema has a check preset but no extract preset
- **POLARITY** negative
- **WHEN** the resolved schema has a registered check preset and no registered extract preset
- **THEN** checking applies its preset and extraction yields nothing
- **AND** extraction does not fall back to a different schema's preset
