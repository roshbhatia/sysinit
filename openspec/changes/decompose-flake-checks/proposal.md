## Why

`flake.nix` is 2210 lines. 19 checks account for roughly 1900 of them, and 1469
of those lines are shell inside 25 Nix string blocks. The file that should
declare what this flake produces is instead the repository's largest test suite.

The cost is not aesthetic. The repository's own shellcheck gate selects files by
a `.sh` extension or a bash shebang, so `flake.nix` matches neither. Every one of
those 1469 shell lines is unlinted. The repository lints `hack/`, `.githooks/`,
`runtime/`, and `skills/` strictly, and never lints its largest body of shell.

Three defects of one class were found in that unlinted region during the
`reorganize-llm-module-layout` change, all in check code:

- The `citelock` check never executed the script it certified, because no change
  ships a `citations.lock` and the loop body never ran.
- A `notify-defect-regressions` assertion was in a polarity where a moved target
  file made it pass silently, and it had been in that state for some time.
- A `perl` replacement containing `$harness` emptied four paths inside a check,
  which no gate would have caught.

Unlinted, untested, and 400 lines from its own `let` bindings is the environment
that produces those.

## What Changes

- Add `checks/`, one file per check, aggregated by `checks/default.nix`. This
  follows `modules/lib/default.nix` and the `harnesses/default.nix` written in the
  previous change: a directory of single-purpose files behind one aggregator.
- Reduce `flake.nix` to output declarations under 300 lines. Move the formatter
  implementation to `flake/formatter.nix` and import the checks from `checks/`.
- Shellcheck each derivation's evaluated `drvAttrs.buildCommand`. This covers the
  shell that Nix executes without changing any check body.
- **BREAKING** for anything that reads a check by line number or imports
  `flake.nix` internals. Nothing in-tree does.

### Non-goals

- Changing what any check asserts. Every check keeps its name, its semantics, and
  its pass and fail conditions. A behavior change inside this move would be
  invisible, because the thing being moved is the test.
- Removing or merging any of the original 19 checks. The new
  `check-bodies-shellcheck` coverage gate is in scope.
- Adopting `flake-parts`. See the design.
- Touching `inputs`, the overlays, or either host configuration.
- Reformatting code outside the expressions changed by this refactor.

## Behavior

- `nix flake check` exits 0, and all 19 original check names remain. This change
  adds only `check-bodies-shellcheck`; concurrent changes can add their own checks.
- Every check derivation is bit-identical before and after, except where a task
  says otherwise. Compare `nix path-info --derivation` per check. A store-path
  change means the body changed, which for a pure move is a defect.
- `flake.nix` is under 300 lines and contains no Nix string block longer than 10
  lines.
- The shellcheck gate covers every other check's evaluated build command. It
  excludes itself because importing its derivation from its own definition recurses.
- The shellcheck gate fails when no other check exposes a build command.
- Each check function declares only the shared values that it uses.

## Impact

Affected code:
- `flake.nix`: roughly 1900 lines leave it.
- New: `checks/default.nix`, one Nix file per check, and
  `flake/formatter.nix`.

Reuse:
- Check aggregation follows the existing `modules/lib/default.nix` pattern.
- Formatter extraction follows the existing `flake/bootstrap.nix` output helper.

Progressive rollout:
- The check relocation landed in `afb26d140` as one commit after comparing every
  derivation path.
- Later simplifications use the current base commit as their preservation baseline.

Impactful and irreversible actions:
- None. No `nh darwin switch` is required, because `checks` are not part of any
  system closure. This change cannot affect the running system, which is the
  reason to do it before any further behavioral work.

Gating signal:
- Run `nix flake check` and compare derivation paths against the current base.
- The code kill switch reverses this follow-up's implementation changes while
  retaining its OpenSpec history. The original relocation commits are unsafe
  rollback targets because later checks depend on the aggregator.
