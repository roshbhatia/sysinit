## ADDED Requirements

### Requirement: aider suppresses commit authorship attribution

The aider config MUST set `attribute-co-authored-by = false` and
`attribute-author = false`, so aider commits match the no-co-author posture of
every other harness in this repo.

#### Scenario: aider commit carries no co-author trailer

- **WHEN** aider creates a commit
- **THEN** the commit message has no `Co-authored-by` trailer
- **AND** the git author is the user, not aider

### Requirement: opencode formatter uses the current top-level form

The opencode top-level `formatter` key is the current documented method for
custom formatters (verified against the opencode formatters docs — it is NOT
deprecated). The `deadnix` formatter config MUST remain in the top-level
`formatter` block. No migration is performed.

#### Scenario: deadnix still formats nix files

- **WHEN** opencode formats a `.nix` file after an edit
- **THEN** `deadnix --edit` runs through the top-level `formatter` config
- **AND** the config is confirmed current, not deprecated

### Requirement: Goose runs in smart-approve mode

The Goose config MUST set `GOOSE_MODE = "smart_approve"` instead of `auto`.

#### Scenario: Goose risk-assesses before acting

- **WHEN** a Goose session performs a tool action
- **THEN** Goose applies risk-assessed approval rather than blanket auto-approval

### Requirement: Codex enables the built-in web-search tool

The Codex config MUST enable the built-in web-search tool.

#### Scenario: Codex can search the web

- **WHEN** a Codex session needs current external information
- **THEN** the web-search tool is available and returns results

### Requirement: opencode and Crush configure a nix LSP

The opencode and Crush configs MUST each declare a `nix` LSP server (`nixd`) so
nix edits get live diagnostics.

#### Scenario: nix diagnostics in opencode

- **WHEN** an opencode session opens or edits a `.nix` file
- **THEN** the `nixd` LSP provides diagnostics for that file

#### Scenario: nix diagnostics in Crush

- **WHEN** a Crush session opens or edits a `.nix` file
- **THEN** the `nixd` LSP provides diagnostics for that file
