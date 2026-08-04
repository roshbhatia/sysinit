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
- Reduce `flake.nix` to what a flake file should hold: `inputs`, `outputs`,
  `packages`, `formatter`, `darwinConfigurations`, `nixosConfigurations`, and
  `checks.${system} = import ./checks { ... }`. Target under 300 lines.
- Extract each check's shell body to a real `.sh` file beside its `.nix` file, read
  back with `builtins.readFile`. Reuses `modules/lib/shell.nix`'s `stripHeaders`,
  which already exists for exactly this: read a script, drop its shebang, embed the
  rest.
- **BREAKING** for anything that reads a check by line number or imports
  `flake.nix` internals. Nothing in-tree does.

### Non-goals

- Changing what any check asserts. Every check keeps its name, its semantics, and
  its pass and fail conditions. A behavior change inside this move would be
  invisible, because the thing being moved is the test.
- Adding, removing, or merging checks.
- Adopting `flake-parts`. See the design.
- Touching `inputs`, the overlays, or either host configuration.
- Reformatting `flake.nix`'s pre-existing unformatted region as part of a
  behavioral commit. That is its own commit.

## Behavior

- `nix flake check` exits 0, and the set of check names before and after is
  identical. Compare `nix flake show --json` output across the change.
- Every check derivation is bit-identical before and after, except where a task
  says otherwise. Compare `nix path-info --derivation` per check. A store-path
  change means the body changed, which for a pure move is a defect.
- `flake.nix` is under 300 lines and contains no Nix string block longer than 10
  lines.
- The shellcheck gate covers every extracted body. `shellcheck` runs over each new
  `checks/*.sh`, and the count of files it reports rises by the number extracted.
- No extracted script interpolates a Nix store path into its body. Each receives
  store paths through environment variables set in its derivation, so the script
  is runnable by hand and `${` never appears in shell context.
- A `require_nonempty` canary covers `checks/`, so the gate fails loudly if the
  directory stops contributing scripts.
- Each extracted script passes `shfmt -i 2 -ci -sr -s`, matching `hack/`.

## Impact

Affected code:
- `flake.nix`: roughly 1900 lines leave it.
- New: `checks/default.nix` plus 19 `<check>.nix` files and the `.sh` bodies that
  have one.
- `modules/lib/shell.nix`: consumed, not modified.

Reuse:
- `checks/default.nix` follows `modules/lib/default.nix`.
- Script extraction follows `modules/lib/shell.nix`'s `stripHeaders` and the
  `runtime/*.sh` pattern, where a script lives as a file and Nix reads it.
- Passing store paths by environment variable follows `runtime/default.nix`'s
  `NOTIFY_EXE`, `SY_REAL`, and `GUARD_EXE`.

Progressive rollout:
- One check per commit, largest first, because the largest carry the most risk and
  the most benefit. `agent-review-readiness` is 388 lines, `managed-file-reconcile`
  274, `notify-defect-regressions` 171.
- Every commit leaves `nix flake check` green, so the work can stop at any point
  with the repository in a better state than it started.

Impactful and irreversible actions:
- None. No `nh darwin switch` is required, because `checks` are not part of any
  system closure. This change cannot affect the running system, which is the
  reason to do it before any further behavioral work.

Gating signal:
- Per check: `nix flake check`, plus a derivation-hash comparison proving the move
  changed nothing. The kill switch is `git revert` of that check's commit.
