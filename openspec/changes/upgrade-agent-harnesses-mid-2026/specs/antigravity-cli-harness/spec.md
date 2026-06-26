## ADDED Requirements

### Requirement: The Gemini-family harness is the Antigravity CLI, configured declaratively

The Gemini-family agent harness MUST be provided by the Antigravity CLI
(`agy`, `pkgs.antigravity-cli`) rather than the retired Gemini CLI
(`pkgs.gemini-cli`), and its package, MCP servers, shared context, and the
ported openspec extension MUST be configured declaratively through
home-manager — no curl-installer, no imperative `agy plugin install` at
runtime, and no auto-updated vendored upstream content. The exact config
paths, the MCP JSON schema, and the plugin manifest format MUST be confirmed
against the built binary before any config is written, because they originate
from third-party documentation rather than primary docs.

#### Scenario: Package is Antigravity, not Gemini CLI

- **WHEN** the home-manager configuration for the Gemini-family harness is built
- **THEN** the installed package is `pkgs.antigravity-cli` (`agy`)
- **AND** `pkgs.gemini-cli` is no longer referenced by that harness config

#### Scenario: MCP servers are declared in agy's JSON config

- **WHEN** the harness config renders its MCP server declarations
- **THEN** the servers are written to agy's JSON MCP config (confirmed path)
  using a JSON formatter, not the TOML `formatForGemini` writer
- **AND** the same MCP servers available to the other harnesses are present

#### Scenario: Shared AGENTS.md provides context

- **WHEN** `agy` starts in a repository that has an `AGENTS.md`
- **THEN** it reads that shared context natively
- **AND** a per-tool `GEMINI.md` is written only if the binary does not pick up
  the shared `AGENTS.md` without one

#### Scenario: openspec extension is ported as a declaratively-vendored plugin

- **WHEN** the harness config is built
- **THEN** the `openspec-awareness` extension is present as an `agy` plugin whose
  files are vendored declaratively under agy's plugin path
- **AND** no `agy plugin install` network step runs at switch time
- **AND** no upstream plugin source is auto-updated

#### Scenario: Config surface is verified against the binary first

- **WHEN** the migration is implemented
- **THEN** the settings path, MCP config path and schema, native `AGENTS.md`
  handling, and plugin manifest format are confirmed against the built
  `pkgs.antigravity-cli` binary before any Nix config is committed
- **AND** if the binary's surface diverges materially from the documented
  assumptions, the migration is re-scoped before any irreversible config change
