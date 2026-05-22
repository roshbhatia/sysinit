## ADDED Requirements

### Requirement: pi-context sourced from npm v1.1.2
The pi configuration SHALL replace the `piPkgContext` git fetch derivation with a `fetchNpmPkg` derivation at npm version 1.1.2.

#### Scenario: pi-context builds from npm
- **WHEN** home-manager is built
- **THEN** `piPkgContext` is fetched from `https://registry.npmjs.org/pi-context/-/pi-context-1.1.2.tgz`

#### Scenario: pi-context skills are available
- **WHEN** pi-context is loaded in a pi session
- **THEN** the skills shipped with v1.1.2 are available to the agent (v1.1.2 ships a `skills/` directory, the git fetch did not)
