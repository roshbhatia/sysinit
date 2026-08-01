## Why

Goose ran its first-run configuration wizard on every start. `goose.nix` set no
`GOOSE_PROVIDER` and no `GOOSE_MODEL`, so goose had no model to talk to and
asked the owner to pick one interactively.

Two further defects surfaced while fixing that.

Goose 1.28 ignores the `shell.allow` and `shell.deny` block that `goose.nix`
generated. Verified against the installed binary: with `deny: ["echo"]` set and
`GOOSE_MODE: auto`, goose still ran `echo`. Goose has no command-pattern deny
surface at all. Its only gate is tool-level `permission.yaml` plus the
`GOOSE_MODE` risk classifier. So the `cross-harness-destructive-command-guard`
spec asserted a guard that never existed, and `formatForGoose` plus
`formatDestructiveForGoose` rendered roughly 180 lines of inert config.

`GOOSE_TOOLSHIM` was `true`. Toolshim routes tool calls through a local ollama
interpreter, for providers with no native tool calling. Every provider the owner
would use has native tool calling, so this only added a hop and a failure mode.

## What Changes

- Set `GOOSE_PROVIDER = "claude-acp"`, so goose drives Claude Code through the
  `claude-agent-acp` adapter this repo already installs
- Template goose's bundled extensions, with `computercontroller` enabled
- Declare bundled extensions as `type = "stdio"` running `goose mcp <name>`,
  not `type = "builtin"`, because a builtin is invisible to an ACP provider
- Template goose's ten in-process platform extensions with explicit `enabled`
  flags
- Turn `GOOSE_TOOLSHIM` off and pin `GOOSE_TELEMETRY_ENABLED` to false
- Delete the inert `shell.allow` / `shell.deny` block and its two formatters
- Retire the goose requirement in `cross-harness-destructive-command-guard`
- Declare `peekaboo` in Homebrew, so goose's `computer_control` tool does not
  shell out to `brew install` mid-session

### Non-goals

- Replacing the destructive-command guard for goose. Goose 1.28 offers no
  mechanism to replace it with. `GOOSE_MODE = "smart_approve"` stays as the
  only available gate, and this proposal records the gap rather than papering
  over it
- Changing the model. Under `claude-acp` the adapter passes no model flag to
  `claude`, so `GOOSE_MODEL` is inert and the model comes from
  `~/.claude/settings.json`
- The `goose-recipes` capability. No recipe behavior changes here

## Capabilities

### Added Capabilities
- `goose-provider-and-extensions`: which provider goose uses, and the rule that
  bundled extensions must be declared as stdio rather than builtin.

### Modified Capabilities
- `harness-allowlist`: goose moves from the formatter list to the non-consumer
  list, because it has no native bash-allowlist concept.
- `cross-harness-destructive-command-guard`: the goose `shell.deny` requirement
  is removed as unimplementable.

## Impact

Modified artifacts:
- `modules/home/programs/llm/config/goose.nix`
- `modules/home/programs/llm/lib/allowlist.nix`
- `modules/darwin/homebrew.nix`
- `openspec/specs/harness-allowlist/spec.md`
- `openspec/specs/cross-harness-destructive-command-guard/spec.md`

Dependencies: none.
