## 1. Skill-owned tool scripts

- **SHAPE** graph

- [x] 1.1 Pilot: move `citation-tools/citelock.sh` to
      `skills/citation-verification/citelock.sh` with `git mv`. The pilot is the
      move whose consumer set is largest, so a wrong assumption about who reads
      the script surfaces on one file rather than two
- [x] 1.2 Add `modules/home/programs/llm/skill-tools.nix` building `citelock` from
      the new path (follows the derivation in `citation-tools/default.nix`, which
      this replaces), and import it from `llm/default.nix` `deps:` 1.1
- [x] 1.3 Delete `modules/home/programs/llm/citation-tools/` `deps:` 1.2
- [x] 1.4 Repoint the `flake.nix` citation gate at the new script path `deps:` 1.1
- [x] 1.5 Repoint the pre-commit hook in `.githooks/` at the same path, then check
      that `rg citation-tools` over the tracked tree finds nothing outside
      `openspec/changes/`. This includes the usage comment inside `citelock.sh`
      itself, which named the deleted directory. That edit is authorized here, and
      it is why `bin/citelock` changes store path `deps:` 1.1
- [x] 1.6 Move `config/wtrun.sh` to `skills/wtrun/wtrun.sh` with `git mv`, move the
      `wtrun` derivation out of `config/notify.nix` into `skill-tools.nix`, and
      drop `notify.wtrun` from the `home.packages` list in `llm/default.nix`
      `deps:` 1.2
- [x] 1.7 Verify the new placement adds no script copy to the installed set:
      evaluate `skillExtraFiles` and confirm it still holds only the
      `adversarial-review` reference and `worklog/scripts/worklog-query.sh`.
      Neither moved script was installed before, so this is prevention, and the
      evaluation alone cannot tell prevention from a no-op. Task 1.11 supplies the
      check that can `deps:` 1.6
- [x] 1.8 Record in `skills/default.nix` that a skill's top-level file is not
      installed and a subdirectory's contents are, because D4 now depends on that
      distinction `deps:` 1.7
- [x] 1.9 Run `nix flake check` and confirm it exits 0 `deps:` 1.7
- [x] 1.10 Adversarial review (`adversarial-review` skill): critics attempt to
      break the skill-tools phase against the proposal `Behavior` criteria, in
      particular the criterion that no skill tree gains a duplicate script;
      revise until the loop reaches a terminal state (see the skill for the
      scaled round cap) `deps:` 1.9. Terminal state CAPPED at K=2 with 0 open objections and no clean round: rounds 1 and 2 each found real defects, so this is not reported as a clean review. Round 2 also caught a fix-induced defect in a round-1 fix
- [x] 1.11 Round 1 finding: extend the `skill-render-shape` flake check to fail
      when a skill-owned CLI source appears in the installed set, so D4 is gated
      rather than only commented. Mutation test it by naming an installed path in
      the guard and confirming the check fails `deps:` 1.10
- [x] 1.12 Round 1 finding: give the `citelock` flake check fixtures, because no
      change ships a `citations.lock` and the gate certifying this phase never
      executed the script. Assert exit 0 for a lockless directory and non-zero for
      a record missing required fields. Add a shellcheck `require_nonempty` canary
      for `llm/skills`, which now holds shell scripts and had none `deps:` 1.10
- [x] 1.13 Round 2 finding, fix-induced: the round-1 fixtures asserted an exit
      code only, so dropping `pkgs.jq` left both green while the format lint never
      ran. `require_tool jq` also dies with status 1. Assert the reason instead:
      the lockless case must report the no-op path, and the bad-lock case must name
      record `unanchored` in a `format:` message. Mutation tested by removing
      `pkgs.jq` `deps:` 1.12
- [x] 1.14 Round 2 finding: replace the two-filename denylist in
      `skill-render-shape` with the list in `skills/tool-sources.nix`, which
      `skill-tools.nix` also builds from, so a third skill-owned CLI cannot escape
      the guard. Mutation tested by adding a third entry pointing at an installed
      path `deps:` 1.13

## 2. Agent runtime

- **SHAPE** graph

- [x] 2.1 Pilot: create `modules/home/programs/llm/runtime/` and move
      `config/agent-group.sh` into it. That script is sourced by `notify.nix`, by
      `agent-review-suffix.sh`, and by two `flake.nix` checks, so it exercises
      every reference kind in this phase on one file
- [x] 2.2 Move the remaining eight `agent-*.sh` scripts into `runtime/`, plus
      `loop-gate.sh`, which is a gate rather than an agent script:
      `agent-notify.sh`, `agent-identity.sh`, `agent-state.sh`, `agent-prompt.sh`,
      `agent-focus.sh`, `agent-review.sh`, `agent-review-suffix.sh`, and
      `agent-busy-panes.sh` `deps:` 2.1
- [x] 2.3 Move `config/sy-gate.sh` to `runtime/sy-gate.sh` `deps:` 2.1
- [x] 2.4 Move `config/claude-bash-guard.sh` to `runtime/bash-guard.sh`, and move
      `config/devin-guard.sh` to `runtime/exit-code-guard.sh`. Both names drop the
      harness prefix, because three harnesses share the first body and two share
      the second `deps:` 2.1
- [x] 2.5 Move `config/notify.nix` to `runtime/default.nix`, keeping its
      `{ pkgs, lib }` calling convention, and update its relative reads to the
      moved script names `deps:` 2.2
- [x] 2.6 Repoint `lib/guards.nix` at `../runtime/bash-guard.sh`, then confirm no
      file under `lib/` reads a path inside the harness layer. Sibling module trees
      are allowed and stay: `instructions.nix` imports `../subagents`, and
      `harness-kit.nix` imports the renderer and the MCP catalog by design. Only
      `guards.nix` reached into the harness directory, and only for the shared
      guard body `deps:` 2.4
- [x] 2.7 Repoint the two harness modules that read the exit-code guard body:
      `config/devin.nix` and `config/gemini.nix` `deps:` 2.4
- [x] 2.8 Repoint `flake.nix`: the `notifyIcons` and `agent-review-readiness`
      imports of `notify.nix`, and the `cfg=` prefix in the
      `agent-review-readiness` and `notify-defect-regressions` checks `deps:` 2.5
- [x] 2.9 Move the shellcheck `require_nonempty` canary from `llm/config` to
      `llm/runtime`, so the check still fails loudly if this subtree stops
      contributing scripts `deps:` 2.2
- [x] 2.10 Update the two comments that name the old notifier path:
      `modules/home/programs/zsh/integrations/seshy-wezterm.zsh` and
      `overlays/inputs.nix` `deps:` 2.5
- [x] 2.11 Run `nix flake check` and confirm it exits 0. Read `git diff -M --stat`
      and confirm all 13 script moves are renames with zero changed lines. Five
      files are edited rather than moved, and each is authorized by a task above:
      `lib/guards.nix`, `flake.nix`, `config/devin.nix`, `config/gemini.nix`, and
      `llm/default.nix`. `runtime/default.nix` is a rename that also carries edits,
      per 2.5 `deps:` 2.8
- [x] 2.12 Adversarial review (`adversarial-review` skill): critics attempt to
      break the runtime phase against the proposal `Behavior` criteria and
      against D1, in particular the claim that no file under `lib/` reads a
      harness path; revise until the loop reaches a terminal state (see the skill
      for the scaled round cap) `deps:` 2.11. Terminal state HALTED at round 1 with
      0 open objections: two objections, both upheld and fixed. Not a clean round
- [x] 2.13 Round 1 finding: add a `require_file` guard for every path
      `notify-defect-regressions` greps. `set -e` exempts the left side of a `&&`,
      and `rg` on a missing path exits 2, so an `rg ... && note ...` assertion
      neither fires nor aborts when its target moves. The `notify` guard is that
      shape and sits in its silent state whenever the regression is absent, so a
      dead guard and a live one looked identical. Mutation tested by pointing it at
      a moved path `deps:` 2.12
- [x] 2.14 Round 1 finding: recalibrate the group-literal stray scan. Its patterns
      required a `$` after the colon, matching an interpolated form `agent_group`
      no longer emits, so it matched nothing, not even the canonical file, and a
      copied definition passed. Dead since the helper moved to `printf`. Added a
      positive control that fails if the patterns stop matching `agent-group.sh`,
      so the scan cannot go dead silently again. Both mutation tested `deps:` 2.13

## 3. Harness layer

- **SHAPE** graph

- [x] 3.1 Pilot: create `harnesses/default.nix` holding the `imports` list
      (follows the aggregating list in `llm/default.nix`), move `config/amp.nix`
      to `harnesses/amp.nix`, and point `llm/default.nix` at `./harnesses`. One
      flat harness proves the aggregator and the `../lib` import depth before the
      other ten move
- [x] 3.2 Move the remaining flat harness modules into `harnesses/`: `codex.nix`,
      `copilot-cli.nix`, `crush.nix`, `devin.nix`, and `goose.nix` `deps:` 3.1
- [x] 3.3 Create `harnesses/claude/`: `default.nix` from `config/claude.nix`,
      `nix-guard.sh` from `config/claude-nix-guard.sh`, `statusline.sh`, and
      `worklog-hook.py` from `config/worklog.py`. Correct the library import depth
      to `../../lib` `deps:` 3.1
- [x] 3.4 Create `harnesses/cursor/`: `default.nix` from `config/cursor.nix`, plus
      `rules/nix.mdc` and `rules/markdown.mdc` from `config/cursor-rules/`.
      Correct the library import depth to `../../lib` `deps:` 3.1
- [x] 3.5 Create `harnesses/gemini/`: `default.nix` from `config/gemini.nix`, plus
      `extensions/openspec-awareness/CONTEXT.md` from `config/gemini-extensions/`.
      Correct the library import depth to `../../lib` `deps:` 3.1
- [x] 3.6 Create `harnesses/opencode/`: `default.nix` from `config/opencode.nix`,
      `render.nix` from `config/opencode-render.nix`, and
      `plugins/sysinit-notify.ts`. Correct the library import depth to `../../lib`
      in BOTH files, and repoint `default.nix` at `./render.nix` `deps:` 3.1
- [x] 3.7 Create `harnesses/pi/`: `default.nix` from `config/pi.nix`,
      `settings-keys.nix`, `vendored-extensions.nix`, `shell-prefix.sh`, all four
      files under `extensions/` (two loose `.ts` files plus the two-file
      `openspec-sidebar/`), and the ten lockfiles under `locks/`. Correct the
      library import depth to `../../lib`, repoint the three internal reads that
      the renames break (`settings-keys.nix`, `vendored-extensions.nix`,
      `shell-prefix.sh`), and keep the sidebar's `source` a directory rather than
      expanding it to files `deps:` 3.1
- [x] 3.8 Repoint the `bridgeArtifacts` paths in `runtime/default.nix` at the pi
      and opencode bridge files in their new homes `deps:` 3.6
- [x] 3.9 Repoint the remaining `flake.nix` sites: the `pi-shell-prefix`,
      `pi-settings-keys`, `pi-vendored-extensions`, and `opencode-render` checks,
      the `harness=` root in `notify-defect-regressions`, and the shellcheck
      canary, which gains `llm/harnesses`. The `require_file` guards added in 2.13
      will name every assertion whose target this phase moved, so run the check
      and fix what it names rather than grepping for sites `deps:` 3.7
- [x] 3.10 Repoint `hack/update-pi.sh`: `PI_NIX`, `LOCKS_DIR`, and the three path
      strings in its printed instructions `deps:` 3.7
- [x] 3.11 Update the shipped path text that teaches where harness config lives:
      `harnesses/cursor/rules/nix.mdc` and `AGENTS.md` `deps:` 3.4
- [x] 3.12 Move the two cross-harness output modules to the module root, not into
      `harnesses/`: `config/acp.nix` becomes `llm/acp.nix`, and
      `config/mcp-servers.nix` becomes `llm/mcp-servers.nix`. Both sit beside the
      `options.nix` that declares the option the second one sets `deps:` 3.1
- [x] 3.13 Delete `modules/home/programs/llm/config/`, then confirm that no
      reference to that directory survives outside `openspec/`. Everything under
      `openspec/changes/` and `openspec/specs/` is exempt and stays untouched: both
      are history, and `openspec/specs/` alone holds 8 such references
      `deps:` 3.9, 3.12
- [x] 3.14 Run `nix flake check` and confirm it exits 0. Read `git diff -M --stat`
      and confirm each moved harness asset is reported as a rename `deps:` 3.13
- [x] 3.15 Adversarial review (`adversarial-review` skill): critics attempt to
      break the harness-layer phase against the proposal `Behavior` criteria and
      against D2 and D8, in particular the criterion that no file under
      `harnesses/` imports the instructions, catalog, or renderer module directly;
      revise until the loop reaches a terminal state (see the skill for the scaled
      round cap) `deps:` 3.14. Run as ONE consolidated review over phases 3, 4 and
      5 rather than three separate loops, recorded here as a deviation. Terminal
      state HALTED at round 1 with 0 open objections; not a clean round

## 4. Eval-library and renderer paths

- **SHAPE** graph

- [x] 4.1 Move `llm/mcp.nix` to `lib/mcp-catalog.nix`, repoint `lib/harness-kit.nix`
      at it, and leave `lib/mcp.nix` alone. The two are the catalog and the
      per-harness formatters, so they keep distinct names
- [x] 4.2 Move `llm/skills.nix` to `skills/render.nix`, and correct its relative
      reads of the registry and of `lib/vocab.nix` `deps:` 4.1
- [x] 4.3 Repoint every importer of the two moved files: `llm/default.nix`,
      `lib/harness-kit.nix`, and the two `flake.nix` sites `deps:` 4.2
- [x] 4.4 Run `nix flake check` and confirm it exits 0. Confirm no top-level file
      under `llm/` shares a name with a directory beside it `deps:` 4.3
- [x] 4.5 Adversarial review (`adversarial-review` skill): critics attempt to
      break the library-path phase against the proposal `Behavior` criteria and
      against D5; revise until the loop reaches a terminal state (see the skill
      for the scaled round cap) `deps:` 4.4. Covered by the consolidated review
      recorded at 3.15

## 5. Guard fail-open fix

- **SHAPE** graph

- [x] 5.1 Write the failing check first: a `flake.nix` check that pipes hook JSON
      carrying a destructive command to devin's and gemini's exec-guard wrappers
      and asserts a non-zero exit, plus JSON carrying an allowed command and
      asserts exit 0 (follows `destructive-guard-fixtures`, which drives the
      assembled guard rather than the source file). Confirm it fails against the
      current script
- [x] 5.2 Change `runtime/exit-code-guard.sh` to call the guard through an injected
      absolute path instead of the bare name `claude-bash-guard` `deps:` 5.1
- [x] 5.3 Inject that path in the devin and gemini wrapper derivations, the way
      `runtime/default.nix` already injects `NOTIFY_EXE` and `SY_REAL` `deps:` 5.2
- [x] 5.4 Rename gemini's wrapper derivation from `devin-guard` to
      `gemini-exit-code-guard`, so two harnesses stop building two different
      derivations under one name `deps:` 5.3
- [x] 5.5 Confirm the check from 5.1 now passes, then mutation test it. Reverting
      5.2 alone is NOT a valid mutation: `writeShellApplication` shellchecks the
      body, an unknown command fails the wrapper build, and a dependency failure
      reads as zero assertion failures. Point the injected path at a missing file
      instead, which is shellcheck-clean and reproduces the original fail-open
      `deps:` 5.4
- [x] 5.6 Run `nix flake check` and confirm it exits 0 `deps:` 5.5
- [x] 5.7 Adversarial review (`adversarial-review` skill): critics attempt to
      break the guard fix against the proposal `Behavior` criteria and against D6
      and D7, in particular whether the fix turns a fail-open guard into an
      over-blocking one; revise until the loop reaches a terminal state (see the
      skill for the scaled round cap) `deps:` 5.6

## 6. Rollout

- [x] 6.1 Record the old-path to new-path map in this change's directory, so the
      seven in-flight changes that name old paths can be read against it
- [x] 6.2 Build only: `nh darwin build`, which writes no system change
- [x] 6.3 Confirm: the owner reads the file-level difference between the current
      generation's result path and the new one, and decides whether every
      difference was intended. The expectation is that no file appears and no file
      disappears, and that the only content difference is the `citelock` store
      path, which moves because the script's usage comment was corrected. Any
      appearing or disappearing file is a defect in an earlier phase, not an
      expected consequence of this one
- [x] 6.4 Apply: `nh darwin switch`, gated on `nix flake check` and
      `nh darwin build` exiting 0 and on 6.3 being confirmed
- [x] 6.5 Confirm: the owner runs one agent session and reports whether the
      notifier, the statusline, and the state bus still fire, which is the
      judgment no check in this change can make
