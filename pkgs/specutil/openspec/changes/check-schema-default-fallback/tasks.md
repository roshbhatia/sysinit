## 1. Resolution plumbing

- **SHAPE** loop
- **STOP** `go test ./...` is green and the CLI probe returns the same schema name the openspec CLI reports
- **MAX-ITERS** 3

- [x] 1.1 Confirm how the openspec CLI exposes its default schema. Resolved: `openspec config get defaultSchema` first, then parse the `Schema:` line from `openspec templates`. Verified side-effect free on openspec 1.6.0.
- [ ] 1.2 Add the CLI probe helper in `internal/graph/manifest.go`, next to `detectSchemaName`. Follow the existing helper shape: return an empty name on any failure, never an error.
- [ ] 1.3 Pin the `openspec templates` parse with a test that runs the real CLI and skips when it is absent.
- [ ] 1.4 Memoize the probe result for the process lifetime.
- [ ] 1.5 Extend `detectSchemaName` with the fallback rung, behind the `SPECUTIL_NO_SCHEMA_FALLBACK` toggle, default off in this slice.
- [ ] 1.6 Make a malformed `openspec/config.yaml` return an error instead of an empty name. Thread it through `CheckConfig` and `ExtractConfig`.
- [ ] 1.7 Add table tests in `internal/graph/manifest_test.go` for every scenario in `specs/rubric-resolution/spec.md`, positive and negative.
- [ ] 1.8 Verify: `go test ./...` and `task lint` are green.
- [ ] 1.9 Adversarial review (`adversarial-review` skill): critics attempt to break the resolution slice against its spec scenarios and the `Decisions` in `design.md`. Revise until no surviving objection or K=4 rounds.

## 2. Reporting

- **SHAPE** graph

- [ ] 2.1 Add the resolution source to the `--list-rules` output in `internal/cli/root.go`. Name the rung and the schema.
- [ ] 2.2 Name the unresolved schema in the `no rubric declared` message at `internal/cli/root.go:611`. `deps:` 2.1
- [ ] 2.3 Add CLI tests in `internal/cli/cli_test.go` covering a CLI-default resolution and a nothing-resolves run. `deps:` 2.1, 2.2
- [ ] 2.4 Verify: run `specutil check --list-rules` by hand in a repository with no `openspec/config.yaml`, with the toggle on. The output names the CLI default as the source. `deps:` 2.3
- [ ] 2.5 Adversarial review (`adversarial-review` skill): critics attempt to break the reporting slice against its spec scenarios and the `Non-goals` in `proposal.md`. Revise until no surviving objection or K=4 rounds. `deps:` 2.4

## 3. Default on

- **SHAPE** loop
- **STOP** the fleet dry run shows no unexpected finding-count change and the toggle is removed
- **MAX-ITERS** 2

- [ ] 3.1 Write the fleet dry run: run `specutil check` over every openspec root on this machine with the toggle off, then with it on, and diff the per-repository finding counts.
- [ ] 3.2 Review the diff. Every repository that gains findings must be one that has openspec artifacts and no `schema:` key.
- [ ] 3.3 Invert the toggle so the fallback is default on and `SPECUTIL_NO_SCHEMA_FALLBACK` disables it.
- [ ] 3.4 Update `README.md` and the `check` long help to state the three-rung ladder and the kill switch.
- [ ] 3.5 Adversarial review (`adversarial-review` skill): critics attempt to break the default-on slice against the gates in `Rollout & Gating`. Revise until no surviving objection or K=4 rounds.

## 4. Rollout

- [ ] 4.1 Verify: `go test ./...` and `task lint` are green. Review `git diff` in full. The fleet dry run diff from 3.2 is recorded in the pull request body.
- [ ] 4.2 Verify: `specutil check` passes on this change itself, and a review decision is recorded with `specutil review set --change check-schema-default-fallback --decision approved`.
- [ ] 4.3 Apply: `git push` the branch and open the pull request.
- [ ] 4.4 Confirm: CI is green, and `specutil check --list-rules` in a config-less repository names the CLI default as the source.
- [ ] 4.5 Confirm: re-run the fleet survey. Every personal openspec root reports a rubric.
