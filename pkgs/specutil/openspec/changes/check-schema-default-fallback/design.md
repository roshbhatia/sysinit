## Context

`internal/graph/manifest.go` holds the resolution ladder. `CheckConfig` and `ExtractConfig` share one helper, `detectSchemaName`, which reads `openspec/config.yaml` and returns the `schema:` value or an empty string. Both callers treat an empty name as "enforce nothing". `internal/cli/root.go:611` prints the `no rubric declared` message and returns nil.

The presets themselves live in `internal/check/presets.go`, keyed by schema name. Nothing in a rule implementation knows a schema name. That separation is correct and this change does not touch it. The change is confined to the one helper that decides the name, plus the message that reports the decision.

The openspec CLI resolves its own default from a compiled constant. On this machine it is patched to `rosh-spec-driven` at two sites in `dist/`. specutil must not duplicate that constant, because a second copy drifts the moment the patch changes.

## Goals / Non-Goals

Goals:

- Make specutil and the openspec CLI agree on which schema governs a repository.
- Keep the resolution ladder readable as a single ordered list in one function.
- Make the resolved source visible to the author.

Non-Goals:

- Failing the build when nothing resolves.
- Adding presets for schemas specutil does not currently know.
- Caching the CLI probe across invocations.

## Decisions

- Decision: probe the installed openspec CLI in two steps. First run `openspec config get defaultSchema`, which the CLI documents as raw and scriptable, and use its value when non-empty. When empty, run `openspec templates` in the repository root and parse the `Schema: <name>` line.
- Alternative rejected: hardcode `rosh-spec-driven` in specutil. Rejected because the name would then live in two places, and the sysinit overlay patch that sets the openspec default would silently stop matching specutil the next time it changes.
- Alternative rejected: read the openspec `dist/*.js` files directly and grep the constant. Rejected because it couples specutil to openspec's build layout, which is not a stable interface.
- Alternative rejected: run `openspec init` into a temporary directory and read the `schema:` it writes. Rejected because it is slow and has side effects, and `openspec templates` reports the same resolution without either.
- Alternative rejected: parse `openspec templates --json`. Rejected because the JSON carries only template paths and their sources, not the schema name. The name appears only in the text output. Filing that gap upstream is worthwhile but is not a blocker.

- Decision: treat a missing or non-responding openspec CLI as "no name", not as an error.
- Alternative rejected: fail when the CLI is absent. Rejected because openspec is an optional peer. specutil already runs in repositories that only have artifacts on disk, and a hard dependency would break them.

- Decision: treat a malformed `openspec/config.yaml` as an error, not as an absent declaration.
- Alternative rejected: fall through to the CLI default on a parse failure. Rejected because a corrupt config is an author mistake, and falling through would apply a rubric the author did not choose while hiding the file they need to fix. Today the parse error is swallowed and returns an empty name, which is the same fail-open bug this change exists to close.

- Decision: report the resolution source in `--list-rules` rather than in every `check` run.
- Alternative rejected: print the source on every run. Rejected because `check` output is consumed by hooks and CI, and an extra line on every invocation is noise. An author debugging resolution reaches for `--list-rules`.

## Rollout & Gating

The change ships in three slices. Each slice is independently reviewable and the behaviour is not default until slice 3.

1. Resolution plumbing. Add the CLI probe and extend `detectSchemaName`, behind an off-by-default toggle. Gate: `go test ./...` green, and the existing resolution tests unchanged.
2. Reporting. Add the source line to `--list-rules` and name the unresolved schema in the `no rubric declared` message. Gate: manual run in a repository with no config file shows the intended source, with the toggle on.
3. Default on. Remove the toggle. Gate: a fleet dry run over every openspec root on this machine, with the diff in finding counts reviewed before the toggle is removed.

Kill switch: the `SPECUTIL_NO_SCHEMA_FALLBACK` environment variable disables the fallback rung after slice 3. A repository that regresses can set it and get the old behaviour without a downgrade.

The gate sequence for this repository is: edit, `go test ./...`, `task lint`, fleet dry run, then `git push`.

## Risks / Trade-offs

- A repository that relied on `no rubric declared` as an implicit opt-out starts failing. Mitigation: slice 3 is gated on a fleet dry run that shows the finding-count diff before the toggle is removed. An affected repository pins `schema: spec-driven` or sets `disable:` in `specutil.yaml`.
- Shelling out to `openspec` adds process-spawn latency to every `check` invocation. Mitigation: the probe runs only when the two earlier rungs both miss, which is the uncommon case, and the result is memoized per process.
- The probe parses a human-readable line, so an upstream wording change breaks it. Mitigation: a test pins the parse against the real CLI, and a parse miss yields no name rather than a wrong name, which degrades to today's behaviour. Ask upstream to add `schema` to `openspec templates --json` so the probe can move off text.
- Making a malformed config an error changes an existing swallow into a failure. This maps to the human-verification checkpoint before push in `tasks.md`.

## Migration Plan

No data migration. The change is behavioural.

1. Verify: `go test ./...` and `task lint` are green on the branch.
2. Verify: run the fleet dry run script and record the per-repository finding-count diff.
3. Apply: `git push` the branch and open the pull request.
4. Confirm: the recorded diff matches the dry run, and `specutil check --list-rules` in a config-less repository names the CLI default as the source.

Rollback: set `SPECUTIL_NO_SCHEMA_FALLBACK=1`, or revert the slice-3 commit. Slices 1 and 2 are inert with the toggle off.

## Adversarial Review

The rubric is the spec scenarios in `specs/rubric-resolution/spec.md` including the negative ones, the `Decisions` above, the three gates in `Rollout & Gating`, and the `Non-goals` in `proposal.md`.

The deterministic half is `specutil check`, which is mandatory and runs on every slice. The LLM critic half is default-on and owner-gated: the `adversarial-review` skill elicits an approve or deny before the loop runs, and the owner may waive it for a slice, recorded as `Adversarial review: waived by owner`. When it runs, independent critics attempt to break the slice with a concrete failing scenario naming a violated rubric item, the author revises against surviving objections, and the loop repeats until no objection survives or K=4 rounds. Under Claude Code the critics are in-process teammates. Elsewhere they are subagents. The skill decides. Per-slice checkmarks live in `tasks.md`.

## Open Questions

Resolved on 2026-07-27: the openspec CLI does expose the effective schema. `openspec templates` run in a root with no `config.yaml` prints `Schema: rosh-spec-driven` and `Source: user`, and it writes nothing. `openspec schema which --all` was the wrong surface. It lists installed schemas and does not mark the default.

Still open:

- Should `ExtractConfig` share the memoized probe, or resolve independently? Sharing is cheaper. Independent resolution is easier to reason about.
- Should the fleet dry run in slice 3 live in `hack/` as a committed script, or stay ad hoc?
- Is `openspec templates` stable enough to depend on, given that `openspec schema` is marked experimental? The `templates` verb carries no experimental warning, but the schema system it reports on does.
