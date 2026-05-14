## ADDED Requirements

### Requirement: cocoindex-code package is installed via activation

`cocoindex-code[full]` MUST be installed on every host this dotfiles repo is
applied to, via a `home.activation` step that invokes `pipx install` with
the `[full]` extra (local embeddings). The install MUST be idempotent —
re-running `nh os switch` SHALL NOT trigger a reinstall when the package is
already present at the expected version, and SHALL NOT fail when the
package is already installed.

#### Scenario: First activation installs cocoindex-code

- **WHEN** a user runs `nh os switch` on a host where `cocoindex-code` has
  never been installed
- **THEN** `pipx list` reports `cocoindex-code` is installed with the
  `full` extra
- **AND** `ccc --version` returns successfully in any fresh shell

#### Scenario: Re-activation is a no-op when the package is current

- **WHEN** a user re-runs `nh os switch` on a host where `cocoindex-code`
  is already installed at the expected version
- **THEN** the activation step exits successfully without touching the pipx
  venv

#### Scenario: Activation fails loudly when pipx is missing

- **WHEN** a user runs `nh os switch` on a host where `pipx` is not on
  PATH (because `home.packages` failed to provide it)
- **THEN** the activation step exits non-zero with a message naming the
  missing `pipx` binary, rather than silently skipping the install

### Requirement: cocoindex MCP server is exposed to every harness

`modules/home/programs/llm/config/mcp-servers.nix` MUST declare a
`cocoindex` MCP server entry whose `command` is `ccc` and whose `args`
is `[ "mcp" ]`. The entry MUST flow through the existing harness-kit at
`modules/home/programs/llm/lib/harness-kit.nix` so that every harness whose
config consumes `kit.mcpServers.servers` (claude, codex, cursor, goose,
gemini, amp, crush, opencode) receives the entry without per-harness
edits.

#### Scenario: All harnesses receive the cocoindex entry

- **WHEN** the rendered config files for claude, codex, cursor, goose,
  gemini, amp, crush, and opencode are inspected after `nh os switch`
- **THEN** each one references a `cocoindex` MCP server with command `ccc`
  and args `[ "mcp" ]` (modulo per-harness formatting differences)

#### Scenario: Adding a new harness automatically inherits the entry

- **WHEN** a new harness is added that consumes `kit.mcpServers.servers`
  via the harness-kit pattern
- **THEN** the new harness's rendered config also includes the cocoindex
  entry without any extra wiring

#### Scenario: Removing the entry removes the tool from every harness

- **WHEN** the `cocoindex` entry is removed from `mcp-servers.nix` and the
  user runs `nh os switch`
- **THEN** none of the rendered harness configs reference cocoindex any
  longer

### Requirement: Project-local index directory is gitignored globally

The user-level gitignore MUST list a pattern matching the per-project
cocoindex index directory (`.cocoindex_code/` anywhere in the tree).
The gitignore is managed by `modules/home/programs/git/default.nix` and
rendered to `~/.config/git/ignore`. The pattern SHALL ensure that index
artifacts created in any project are not staged or committed in that
project, without requiring per-repo gitignore edits.

#### Scenario: Index artifacts in an unrelated repo are ignored

- **WHEN** a `.cocoindex_code/` directory is created inside an unrelated
  git repository during a search call
- **THEN** `git status` in that repository shows no untracked entries for
  the directory

#### Scenario: Per-repo gitignore is not required

- **WHEN** a contributor clones a project that does not list
  `.cocoindex_code/` in its own `.gitignore`
- **THEN** the index directory created during agent use SHALL still be
  excluded by the user-level gitignore alone, without per-repo edits

### Requirement: Search tool is the only auto-exposed entry point

The MCP server entry MUST expose `cocoindex:search` as the canonical
read-only search tool consumed by harnesses. The skill SHALL NOT instruct
agents to invoke any write-mutating tool the MCP server might add in
future versions (e.g., a hypothetical `index` MCP tool); those remain
user-driven via the CLI.

#### Scenario: Search returns chunks for a semantic query

- **WHEN** an agent in any harness calls `cocoindex:search` with a
  natural-language query against a project whose index exists
- **THEN** the tool returns chunks with file path, language, content, line
  range, and similarity score

#### Scenario: Search bootstraps a missing index on first call

- **WHEN** an agent calls `cocoindex:search` with `refresh_index=True` in
  a project where `.cocoindex_code/` does not yet exist
- **THEN** the tool creates the index, populates it, and returns chunks
  for the query — or returns an error the skill instructs the agent to
  catch and fall back to `rg`

#### Scenario: Unknown tool name is rejected

- **WHEN** an agent invokes a tool name on the cocoindex MCP server that
  is not exposed (e.g., a tool from a future version that this entry
  doesn't claim)
- **THEN** the MCP server returns an error and the agent treats the
  attempt as failed rather than retrying with different arguments
