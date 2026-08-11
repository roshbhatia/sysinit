## Why

`detectSchemaName` in `internal/graph/manifest.go` reads `openspec/config.yaml` and nothing else. A repository that has no `config.yaml`, or whose `config.yaml` omits `schema:`, resolves an empty name. `CheckConfig` then returns a zero config and `specutil check` prints `no rubric declared` and exits 0. The openspec CLI in that same repository does resolve a schema, because it falls back to its own compiled default. The two tools disagree about which schema governs the repository, and the disagreement fails open: the gate reports success while enforcing nothing.

This was observed on 2026-07-27 across 10 openspec roots on this machine. Each inherited `rosh-spec-driven` from the openspec CLI default and each got no rubric from `specutil check`.

The openspec CLI does self-heal. `dist/utils/change-utils.js:127` writes `schema: <default>` into `config.yaml` the next time a change is created in that root. The divergence is therefore bounded by "until the next `openspec change new`". That does not make it harmless. The roots that go longest without a new change are the stale ones, and those are exactly the roots whose existing artifacts most need the gate.

## What Changes

- Extend `detectSchemaName` so an absent or `schema:`-less `openspec/config.yaml` falls back to the schema the openspec CLI itself would resolve, instead of yielding an empty name.
- Read the fallback from the openspec installation rather than hardcoding a name in specutil, so a patched or forked default stays authoritative in one place.
- Report the resolution source in `specutil check --list-rules`, so an author can see whether the rubric came from `specutil.yaml`, from `openspec/config.yaml`, or from the CLI default.
- Keep the fail-open behaviour when no schema resolves at all, and keep the current message. An unrecognized schema name still enforces nothing.
- Apply the same fallback to `ExtractConfig`, which shares `detectSchemaName` and has the identical gap.

### Non-goals

- Changing any rule in the `rosh-spec-driven` preset.
- Adding a preset for `spec-driven`. A repository pinned to upstream stays unchecked by design.
- Making `specutil check` fail when no rubric resolves. That is a separate decision and would break every repository that has no schema today.
- Writing `openspec/config.yaml` on the user's behalf.

## Capabilities

### New Capabilities

- `rubric-resolution`: how specutil decides which rubric governs a repository, and what it reports about that decision.

### Modified Capabilities

None.

## Impact

- Affected files: `internal/graph/manifest.go` (`detectSchemaName`, `CheckConfig`, `ExtractConfig`), `internal/cli/root.go` (the `--list-rules` output and the no-rubric message), and their tests.
- Reuse: the fallback follows the existing precedence ladder in `CheckConfig` and `ExtractConfig`. It adds one rung at the bottom and introduces no new resolution path.
- Impactful actions that need human-verification checkpoints in `tasks.md`:
  - `git push` to `main`.
  - No network writes, no schema migration, no system config change.
- Blast radius: any repository that has openspec artifacts and no `schema:` key starts getting checked. Findings appear where there were none. This is the intent, and it is why the rollout ships behind a report-only slice first.
- Gating signal: `go test ./...` then `specutil check --list-rules` in a repository with no `config.yaml` then a fleet dry run before the behaviour is made default.
