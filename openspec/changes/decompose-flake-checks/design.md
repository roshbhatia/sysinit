## Context

`flake.nix` is 2210 lines. 19 checks hold roughly 1900 of them, and 1469 lines sit
inside 25 Nix string blocks as shell. The repository's shellcheck gate selects
files by a `.sh` extension or a bash shebang, so none of that shell is linted.

The move is safe to verify exactly, which is what makes it worth doing at all: a
check's derivation path is a pure function of its inputs, so a relocation that
changes nothing must leave all 19 paths identical. That is a stronger statement
than "the checks still pass", and it is the gate for every phase here.

Beyond length, four smells are in scope:

- Duplicated shell preludes. `note()`, `fail=0`, `expect_rc`, and `expect_out` are
  re-declared per check with small variations.
- Assertions that cannot fail. Three were found and fixed during
  `reorganize-llm-module-layout`, all in this region, all invisible because a
  never-matching pattern looks exactly like a passing one.
- Store paths interpolated into shell bodies, which is how a `perl` edit emptied
  four paths during that change and why `${` in shell context is a hazard.
- `cacheBundleFor` sits among the checks and is a packages helper.

## Goals / Non-Goals

Goals:
- `flake.nix` declares outputs and nothing else, under 300 lines.
- Every check is one file, discoverable by name.
- Every extracted shell body is linted by the gate that already exists.
- A check receives store paths as environment variables, so its script runs by
  hand.

Non-Goals:
- Changing what any check asserts. Verified by derivation-path equality, not by
  reading.
- Adding, merging, or removing checks.
- Adopting `flake-parts`.
- Fixing the pre-existing unformatted region of `flake.nix` in the same commit as
  a move.
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
are recorded up front.

- Alternative rejected: run `nix flake check` and call it verified. Rejected
  because a check that passes both before and after tells you nothing about
  whether its body survived intact, and the bodies here contain assertions that
  pass when they match nothing.

### D3. Extract the shell body only where the check has a real one

A check that is mostly Nix with a three-line string stays one `.nix` file. A check
whose body is dozens of lines of shell gets a `.sh` beside it. The threshold is
whether shellcheck would have anything to say.

- Alternative rejected: extract every string, uniformly. Rejected because a
  three-line body in its own file costs a reader one more hop and gains no lint.

### D4. Store paths arrive as environment variables

An extracted script receives `$AGENT_REVIEW`, `$GUARD`, `$CFG` and so on, set in
the derivation. The script never contains `${`.

- Alternative rejected: keep interpolating store paths into the body and read it
  with `builtins.readFile`. Rejected because the two cannot coexist: `${` is Nix
  interpolation inside a Nix string and a shell parameter expansion inside a
  script, so a file that is both is a file no tool reads correctly. This is also
  what makes the extracted script runnable by hand.

### D5. One shared prelude, sourced by the extracted scripts

`checks/lib/prelude.sh` declares `note`, `fail`, `expect_rc`, and `expect_out`
once. It is a real file, so shellcheck lints it once and every consumer inherits
the fix.

- Alternative rejected: leave each check's prelude inline. Rejected because the
  variants already differ: some `note` implementations set `fail=1` and some do
  not, which is the kind of difference that makes one check's failure silent.

### D6. Largest checks first

`agent-review-readiness` (388 lines), `managed-file-reconcile` (274), and
`notify-defect-regressions` (171) move first. They carry the most risk and the
most benefit, and doing them first means a mid-change stop still leaves the
repository better.

- Alternative rejected: smallest first, to build confidence. Rejected because the
  small ones prove nothing about the hard cases, and stopping halfway would leave
  the worst code in place.

## Rollout & Gating

Per check: move it, then compare its `drvPath` against the recorded baseline. A
mismatch means the body changed and the move is wrong. Then `nix flake check`.

Phase 1 stands up `checks/default.nix` and moves one check as a pilot. Phase 2
moves the rest in descending size order. Phase 3 removes the now-empty region from
`flake.nix`, moves `cacheBundleFor` to where packages are built, and formats.

No `nh darwin switch` at any point: `checks` are in no system closure, so this
change cannot affect the running machine. The kill switch is `git revert` per
check.

## Risks / Trade-offs

- An extracted body changes behavior invisibly, because the thing moved is the
  test. Mitigation: derivation-path equality per check, which is exact.
- A `${` left in an extracted script becomes a shell expansion instead of a Nix
  interpolation, or vice versa. Mitigation: D4 forbids store-path interpolation in
  extracted scripts, and the derivation-path comparison catches any change in what
  the script receives.
- The new `.sh` files enter the shellcheck gate and fail on pre-existing findings
  that were never linted. Mitigation: that is the point, and each finding is fixed
  or given a targeted `shellcheck disable` with a reason, per the repository rule.
  A finding that indicates a real defect is split out rather than silenced.
- `checks/default.nix` must pass through whatever each check needs (`inputs`,
  `self`, `notifyIcons`, `lib`, `pkgs`). A wide argument set makes the seam vague.
  Mitigation: the aggregator takes one attrset and each check declares what it
  destructures, so the dependency is visible per file.

## Migration Plan

1. Record all 19 `drvPath` values. Done before any edit.
2. Per check: move, compare `drvPath`, run `nix flake check`, commit.
3. After the last one, remove the dead region from `flake.nix` and confirm it is
   under 300 lines.
4. Format `flake.nix` in its own commit, which also clears the pre-existing
   unformatted region.

Rollback: `git revert` the commit for that check. Every commit is one check.

## Adversarial Review

The rubric is the proposal's `Behavior` criteria, the `Decisions` above, the
`Rollout & Gating` gates, and the proposal's `Non-goals`.

Two halves per the `adversarial-review` skill. `specutil check` is mandatory every
phase. The LLM critic loop is default-on and owner-gated, and a waiver is recorded
as `Adversarial review: waived by owner`. When it runs, independent critics attempt
to break the phase with a concrete failing scenario naming a violated rubric item,
the author revises against surviving objections, and the loop runs to a terminal
state. The skill scales the round cap and stops early on non-convergence or
fix-induced churn. A cap hit is reported as open objections, never as a pass.

The critic instruction that matters here: verify the move by derivation path, not
by reading the diff. A 400-line relocation is not reviewable by eye, and saying so
is more honest than pretending otherwise.

## Open Questions

- Whether the never-matching-assertion audit should follow immediately. Three such
  defects were found in this region by accident. Nothing has looked on purpose.
