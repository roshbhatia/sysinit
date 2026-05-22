## ADDED Requirements

### Requirement: Quick-select patterns for developer artifacts
WezTerm's `quick_select_patterns` SHALL include patterns for the following artifact types, in addition to the defaults:

- **Nix store hashes**: 32-character lowercase alphanumeric strings prefixed by `/nix/store/`
- **Full Nix store paths**: the complete `/nix/store/<hash>-<name>` path
- **Git SHAs**: 7-character and 40-character lowercase hex strings
- **UUIDs**: standard 8-4-4-4-12 hyphenated format
- **Absolute file paths**: strings beginning with `/` containing no whitespace

#### Scenario: Select a Nix store path
- **WHEN** the user triggers quick-select (`CTRL+F`) and the screen contains `/nix/store/abc123…-foo-1.0`
- **THEN** the full store path is offered as a selectable candidate

#### Scenario: Select a short git SHA
- **WHEN** the user triggers quick-select and the screen contains a 7-character hex string like `a1b2c3d`
- **THEN** the SHA is offered as a selectable candidate

#### Scenario: Select a UUID
- **WHEN** the user triggers quick-select and the screen contains `550e8400-e29b-41d4-a716-446655440000`
- **THEN** the UUID is offered as a selectable candidate

#### Scenario: Select an absolute path
- **WHEN** the user triggers quick-select and the screen contains `/Users/rshnbhatia/foo/bar.txt`
- **THEN** the path is offered as a selectable candidate
