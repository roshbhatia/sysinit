## Context

`flake.nix` is 2210 lines. 19 checks hold roughly 1900 of them, and 1469 lines sit
inside 25 Nix string blocks as shell. The repository's shellcheck gate selects
files by a `.sh` extension or a bash shebang, so none of that shell is linted.

The move is safe to verify exactly, which is what makes it worth doing at all: a
check's derivation path is a pure function of its inputs, so a relocation that
changes nothing must leave all 19 paths identical. That is a stronger statement
than "the checks still pass", and it is the gate for every phase here.

Beyond length, four smells are in scope:

- Every check declared the same six shared arguments, although most used one or two.
- Assertions that cannot fail. Three were found and fixed during
  `reorganize-llm-module-layout`, all in this region, all invisible because a
  never-matching pattern looks exactly like a passing one.
- Shell inside Nix strings bypassed the repository shellcheck gate.
- `cacheBundleFor` sits among the checks and is a packages helper.

## Goals / Non-Goals

Goals:
- `flake.nix` declares outputs and nothing else, under 300 lines.
- Every check is one file, discoverable by name.
- Every other check's evaluated build command passes shellcheck.
- Each check declares only the shared values that it reads.

Non-Goals:
- Changing what any check asserts. Verified by derivation-path equality, not by
  reading.
- Adding, merging, or removing any of the original 19 checks. The new
  `check-bodies-shellcheck` coverage gate is in scope.
- Adopting `flake-parts`.
- Reformatting code outside the expressions changed by this refactor.
- Auditing all 19 checks for never-matching assertions. That is real work and it is
  its own change; this one makes it possible by putting each check where it can be
  read.

## Decisions

### D1. A plain `checks/` directory, not `flake-parts`

`checks/default.nix` takes the arguments the checks need and returns the attrset.
`flake.nix` calls `import ./checks { ... }`. This is the pattern already used three
times in this repository: `modules/lib/default.nix`, `modules/home/programs/llm/lib/default.nix`,
and `harnesses/default.nix`.

- Alternative rejected: `flake-parts`. Rejected because it adds an input and a
  second idiom for module composition to a repository that already has a working
  one, and it solves distribution across many flakes, which this single-user
  repository does not have.

### D2. Derivation-path equality is the gate, per check

Each move is verified by comparing that check's `drvPath` before and after. All 19
are recorded up front. For checks whose input is the full source tree, normalize
only the expected source path and compare `drvAttrs.buildCommand` too.

- Alternative rejected: run `nix flake check` and call it verified. Rejected
  because a check that passes both before and after tells you nothing about
  whether its body survived intact, and the bodies here contain assertions that
  pass when they match nothing.

### D3. Lint each evaluated check body in place

`check-bodies-shellcheck` reads every other check's `drvAttrs.buildCommand`.
Shellcheck sees the exact shell that Nix executes, including resolved store paths.
The gate excludes itself because importing its own derivation recurses.

- Alternative rejected: extract shell into sibling files. Rejected because this
  rewrites each derivation only to expose its shell to a linter.

### D4. Each check declares its actual dependencies

Every check accepts only the shared values that it reads. The aggregator can add
a shared value without adding an unused argument to every check.

- Alternative rejected: give each check one fixed argument signature. Rejected
  because 19 checks declared six values while most used only one or two.

### D5. Keep small shell helpers local

The repeated helper names do not share one contract. `expect_rc` and `expect_out`
occur in one check. The `note` variants have different output and failure rules.

- Alternative rejected: add `checks/lib/prelude.sh`. Rejected because the shared
  file adds a dependency without removing equivalent implementations.

### D6. Move the checks as one verified set

The relocation landed in `afb26d140` after comparing all 19 derivation paths.

- Alternative rejected: one commit per check. Rejected because the shared
  aggregator and the source-scanning check change as one seam.

## Rollout & Gating

Compare every `drvPath` against the base revision. For a source-input mismatch,
normalize the source path and compare the build command. Then run
`nix flake check`.

Phase 1 adds `checks/default.nix` and moves one pilot check. Phase 2 moves the
remaining checks and lints their evaluated build commands. Phase 3 reduces and
formats the changed expressions in `flake.nix`.

No `nh darwin switch` is needed because checks are outside every system closure.
The code kill switch reverses this follow-up's implementation changes while
retaining its OpenSpec history. Reverting the original relocation commits is
unsafe because later checks depend on the aggregator.

## Risks / Trade-offs

- A source-scanning check changes derivation path when files move. Mitigation:
  record these expected exceptions separately from body changes.
- Shellcheck cannot see variables that stdenv supplies or store paths available
  only during a build. Mitigation: exclude only SC2154 and SC1091 at the gate.
- A future check can omit `drvAttrs.buildCommand`. Mitigation: direct attribute
  access fails evaluation instead of filtering that check out.

## Migration Plan

1. Record all 19 `drvPath` values before the relocation.
2. Move all checks behind one aggregator and compare every path.
3. Remove the dead region from `flake.nix` and confirm it is under 300 lines.
4. Run `nix flake check`.

Rollback the implementation paths from this follow-up: `checks/`, `flake.nix`,
and `flake/formatter.nix`. Retain these OpenSpec artifacts because they record
decisions already implemented by `1642fdc02` and the rollback history. Do not
revert `afb26d140` or `1642fdc02`. Later commits add checks through their
aggregator.

## Adversarial Review

The rubric is the proposal's `Behavior` criteria, the `Decisions` above, the
`Rollout & Gating` gates, and the proposal's `Non-goals`.

Two halves per the `adversarial-review` skill. `specutil check` is mandatory. The
relocation landed before this artifact caught up, so one whole-change critic loop
verifies every phase. Each review task records the same terminal outcome. The loop
is default-on and owner-gated, and a waiver is recorded as `Adversarial review:
waived by owner`. Independent critics attempt to break the change with a concrete
failing scenario naming a violated rubric item. The author revises against
surviving objections until the loop reaches a terminal state. A cap hit is reported
as open objections, never as a pass.

The critic instruction that matters here: verify the move by derivation path, not
by reading the diff. A 400-line relocation is not reviewable by eye, and saying so
is more honest than pretending otherwise.

## Open Questions

- Whether the never-matching-assertion audit should follow immediately. Three such
  defects were found in this region by accident. Nothing has looked on purpose.
