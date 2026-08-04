## MODIFIED Requirements

### Requirement: The custom schema resolves from the package

The OpenSpec derivation MUST install `rosh-spec-driven` under its package
schema directory. Resolution MUST NOT depend on a project-local schema or an
XDG user override.

#### Scenario: Package schema resolves outside sysinit

- **POLARITY** positive
- **WHEN** `openspec schema which rosh-spec-driven` runs from a temporary repository with empty XDG data
- **THEN** it reports `Source: package`

#### Scenario: Package omits the custom schema

- **POLARITY** negative
- **WHEN** the package output does not contain `rosh-spec-driven/schema.yaml`
- **THEN** the default-schema check fails

### Requirement: The installed default is checked

The default-schema check MUST use the installed OpenSpec package without
copying schema files from the repository.

#### Scenario: Bare change uses the custom default

- **POLARITY** positive
- **WHEN** `openspec new change probe` runs with empty HOME and XDG data
- **THEN** the generated config names `rosh-spec-driven`

#### Scenario: A project schema hides a package defect

- **POLARITY** negative
- **WHEN** a check attempts to copy a project schema into its test environment
- **THEN** review rejects the check because it does not test the installed package alone
