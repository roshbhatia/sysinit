## 1. Provider and scalar settings

- **SHAPE** graph
- [x] 1.1 Verify: probe the installed goose for its ACP provider id and confirm
      `claude-acp` spawns the repo's `claude-agent-acp` adapter `deps: none`
- [x] 1.2 Set `GOOSE_PROVIDER = "claude-acp"` and `GOOSE_MODEL = "opus"` in
      `goose.nix` `deps: 1.1`
- [x] 1.3 Verify: confirm the adapter passes no model flag to `claude`, and
      comment `GOOSE_MODEL` as inert `deps: 1.2`
- [x] 1.4 Set `GOOSE_TOOLSHIM = false` and pin `GOOSE_TELEMETRY_ENABLED = false`
      `deps: none`
- [x] 1.5 Adversarial review (`adversarial-review` skill): waived by owner. The
      phase was built and verified before the per-phase gate existed, so a
      retroactive critic loop would only review shipped and confirmed work

## 2. Extensions

- **SHAPE** graph
- [x] 2.1 Verify: enumerate goose's bundled MCP servers (`goose mcp <name>`) and
      its platform extensions `deps: none`
- [x] 2.2 Verify: prove a `type = "builtin"` extension is invisible under
      `claude-acp`, and a `type = "stdio"` one is forwarded as
      `mcp__<name>__<tool>` `deps: 2.1`
- [x] 2.3 Template the bundled servers as stdio, with `computercontroller` and
      `autovisualiser` on, `memory` and `tutorial` off `deps: 2.2`
- [x] 2.4 Template the ten platform extensions with explicit `enabled` flags,
      `extensionmanager` and `code_execution` off `deps: 2.1`
- [x] 2.5 Verify: build the generated `config.yaml` and run goose against it,
      confirming all seven computercontroller tools reach the agent `deps: 2.3,2.4`
- [x] 2.6 Adversarial review (`adversarial-review` skill): waived by owner. The
      phase was built and verified before the per-phase gate existed, so a
      retroactive critic loop would only review shipped and confirmed work

## 3. Dead allowlist config

- **SHAPE** graph
- [x] 3.1 Verify: prove `shell.deny` has no effect in goose 1.28 `deps: none`
- [x] 3.2 Delete the `shell` block from `goose.nix` `deps: 3.1`
- [x] 3.3 Delete `formatForGoose` and `formatDestructiveForGoose` from
      `lib/allowlist.nix`, and restate the comments that named goose `deps: 3.2`
- [x] 3.4 Verify: evaluate `lib/allowlist.nix` and confirm neither name remains
      `deps: 3.3`
- [x] 3.5 Adversarial review (`adversarial-review` skill): waived by owner. The
      phase was built and verified before the per-phase gate existed, so a
      retroactive critic loop would only review shipped and confirmed work

## 4. Peekaboo

- **SHAPE** graph
- [x] 4.1 Verify: read the tap and formula name out of the goose binary
      `deps: none`
- [x] 4.2 Add `steipete/tap` and `steipete/tap/peekaboo` to
      `modules/darwin/homebrew.nix` `deps: 4.1`
- [x] 4.3 Verify: run `nh darwin switch .` and confirm `peekaboo` is on PATH
      `deps: 4.2`
- [x] 4.4 Adversarial review (`adversarial-review` skill): waived by owner. The
      phase was built and verified before the per-phase gate existed, so a
      retroactive critic loop would only review shipped and confirmed work

## 5. Close out

- **SHAPE** graph
- [x] 5.1 Run `nix flake check` `deps: 4.3`
- [x] 5.2 Adversarial review (`adversarial-review` skill): waived by owner. The
      phase was built and verified before the per-phase gate existed, so a
      retroactive critic loop would only review shipped and confirmed work
- [x] 5.3 Archive this change, with `--skip-specs`: the schema has no specs
      artifact any more, so promoting this change's three delta files would grow
      a corpus the fork abandoned `deps: 5.1`
