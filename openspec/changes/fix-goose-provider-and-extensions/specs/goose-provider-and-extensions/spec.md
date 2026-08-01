## ADDED Requirements

### Requirement: Goose ships a provider and model, so no wizard runs

`modules/home/programs/llm/config/goose.nix` MUST write both `GOOSE_PROVIDER`
and `GOOSE_MODEL` into `~/.config/goose/config.yaml`. The provider MUST be
`claude-acp`, which drives Claude Code through the `claude-agent-acp` adapter
already registered in `lib/acp.nix`.

`GOOSE_MODEL` is required by goose but inert for this provider: the adapter
spawns `claude` with no model flag, so the model resolves from
`~/.claude/settings.json`. The field MUST carry a comment saying so, because a
reader would otherwise change it and see no effect.

#### Scenario: Goose starts without prompting
- **POLARITY** positive
- **WHEN** `goose run --no-session -t "say ok"` runs after activation
- **THEN** goose answers without presenting the provider or model wizard

#### Scenario: GOOSE_MODEL does not select the model
- **POLARITY** negative
- **WHEN** goose runs twice under `claude-acp`, once with `--model opus` and
  once with `--model haiku`, each asking the model to state its own id
- **THEN** both runs report the same model id, because the flag never reaches
  `claude`

### Requirement: Bundled extensions are stdio, never builtin

Goose's bundled MCP servers MUST be declared with `type = "stdio"`, `cmd` set
to the `goose` binary's store path, and `args = [ "mcp" <name> ]`. They MUST
NOT be declared with `type = "builtin"`.

Both shapes load the same server. A builtin runs in-process and is therefore
never forwarded to an ACP provider, so under `claude-acp` a builtin extension
contributes zero tools. A stdio extension is forwarded and its tools appear to
the agent as `mcp__<name>__<tool>`.

#### Scenario: computercontroller reaches the agent
- **POLARITY** positive
- **WHEN** goose runs under `claude-acp` with `computercontroller` declared as
  stdio, and is asked to name its computercontroller tools
- **THEN** it reports all seven: `automation_script`, `cache`,
  `computer_control`, `docx_tool`, `pdf_tool`, `web_scrape`, `xlsx_tool`

#### Scenario: A builtin declaration hides the extension
- **POLARITY** negative
- **WHEN** `computercontroller` is declared as `type = "builtin"` and goose runs
  under `claude-acp`
- **THEN** the agent reports no computercontroller tool, and the extension is
  silently unusable

### Requirement: Every extension goose knows carries an explicit enabled flag

`goose.nix` MUST declare an `enabled` value for each of goose's ten platform
extensions and each bundled MCP server it templates. Goose seeds absent
extensions with its own defaults on every run, so an undeclared extension is
goose-owned rather than nix-owned.

`extensionmanager` MUST be disabled, because it enables and disables extensions
by rewriting `config.yaml`, which this module owns. `memory` MUST be disabled,
because the shared `basic-memory` MCP server supersedes it.

#### Scenario: Disabled extension survives a goose rewrite
- **POLARITY** positive
- **WHEN** goose rewrites `config.yaml` during a session, then home-manager
  activation runs
- **THEN** `extensionmanager` and `memory` are still `enabled: false`

### Requirement: Toolshim is off

`GOOSE_TOOLSHIM` MUST be `false`. Toolshim routes tool calls through a local
ollama interpreter, for providers with no native tool calling. `claude-acp` has
native tool calling, so enabling it adds a hop and a failure mode with no gain.

#### Scenario: Toolshim is not enabled
- **POLARITY** positive
- **WHEN** the generated `config.yaml` is read
- **THEN** `GOOSE_TOOLSHIM` is `false`

### Requirement: Peekaboo is declared, not auto-installed

`computer_control` shells out to `brew install steipete/tap/peekaboo` the first
time it runs. `modules/darwin/homebrew.nix` MUST declare the `steipete/tap` tap
and the `steipete/tap/peekaboo` formula, so that install is declarative rather
than an unreviewed command an agent triggers mid-session.

#### Scenario: Peekaboo present before first use
- **POLARITY** positive
- **WHEN** `nh darwin switch .` completes
- **THEN** `peekaboo` is on PATH, and goose's auto-install branch never runs
