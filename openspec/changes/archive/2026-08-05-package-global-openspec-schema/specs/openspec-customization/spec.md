## MODIFIED Requirements

### Requirement: The custom schema resolves from the package

The OpenSpec derivation MUST install `rosh-spec-driven` under its package
schema directory. Resolution MUST NOT depend on a project-local schema or an
XDG user override.

#### Scenario: Fork resolves outside sysinit

- **POLARITY** positive
- **WHEN** `openspec schema which rosh-spec-driven` runs from a directory that is not the sysinit repo and has no project-local schema
- **THEN** it reports `Source: package`

#### Scenario: XDG data is empty

- **POLARITY** positive
- **WHEN** a temporary project uses an empty `XDG_DATA_HOME`
- **THEN** `openspec new change` still resolves `rosh-spec-driven`

#### Scenario: Package omits the custom schema

- **POLARITY** negative
- **WHEN** the package output does not contain `rosh-spec-driven/schema.yaml`
- **THEN** the default-schema check fails
