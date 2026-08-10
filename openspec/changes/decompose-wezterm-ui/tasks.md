## 1. Measure before moving anything

- **SHAPE** graph

- [x] 1.1 Gather: record the wezterm configuration's derivation path, so every
      later phase has something to compare against. Record it in this folder, in
      the shape `make-sysinit-composable` phase 1 used for its host baselines.
      `deps:` none

      Recorded in `baseline/lua.path` and `baseline/lua.files`, in the two-file
      shape that change used: one line naming the attribute and its store path,
      and a sorted manifest beside it so a failure reads as a list rather than
      as one moved hash.

      The referent is `xdg.configFile."wezterm/lua".source`, which evaluates to
      `/nix/store/afl8fbmsibp0wjlmjdqswdbcrw7la5sc-lua`. That attribute is the
      right one to gate on because 1.3 shows it is the whole lua tree installed
      as one directory, so its path is a pure function of the file set and
      nothing else. A host `drvPath` would also move for reasons that have
      nothing to do with this change.

      Seven files today. `ui.lua` is 63,352 bytes, over four times the next
      largest, `keybindings.lua` at 14,628.
- [x] 1.2 Gather: list every local defined inside `M.setup`, with the set of
      other locals it reads. This is the input to decision 2's boundary, and
      guessing it from function names is how a shared cache ends up duplicated.
      `deps:` 1.1

      The map is `setup-locals.md`: 59 declarations at depth 1, one row each,
      with the method and its two limits stated in the file rather than assumed.

      Worth recording that the first pass was WRONG in a way that would have
      moved code for no reason. It reported `touch_workspace` reading
      `workspace_last_active` and `pane_badge_color` reading `lantern`. Neither
      is a read: the first is `wezterm.GLOBAL.workspace_last_active`, a field
      that happens to share a local's name, and the second is a statement
      sitting between two declarations that a value-span heuristic swept into
      the wrong body. Both looked like forward references, which is a real Lua
      hazard, so both were checked against the source before being believed.
      That is the failure this task exists to prevent, found in this task's own
      output.

      THE RESULT CHANGES DECISION 2, and this is the finding that justifies the
      task. The transitive closure of `agent_session_states` is nine names:
      `agent_deck_ok` and `agent_deck`, `agent_state_rank`, `pane_repo`,
      `read_pane_record`, `pane_agent_state`, `rollup_cache`,
      `compute_agent_session_states`, and `agent_session_states` itself.

      Six of those nine are ALSO read by `session_tree`: the agent-deck handle,
      `agent_state_rank`, `pane_repo`, `read_pane_record`, and
      `pane_agent_state`. Decision 2 says to extract "the rollup and the mux
      walk first, as one module that both the tab bar and the session tree
      consume". The tree does not consume the rollup. It consumes the pane
      primitives underneath it and reduces them differently. Moving the rollup
      and its primitives into one module and having the tree require it makes
      the tree depend on a cache it never reads.

      So the boundary is two layers, not one. A pane-primitives layer holding
      the six shared names, and a rollup layer on top holding `rollup_cache`,
      `compute_agent_session_states`, and `agent_session_states`. `session_tree`
      requires the first and not the second. Phase 2 is written against one
      module; this is the correction it needs before 2.1 runs.

      Two other measurements worth having. `agent_session_states` is the only
      name outside the rollup that anything reads: `agent_status`,
      `session_chips`, and the `wm` block reach it, and nothing outside reaches
      `rollup_cache` or `compute_agent_session_states` directly. That is a clean
      public surface and it means the extraction has one export, not three. And
      the `wm` block is 519 lines reading 23 other locals, which makes it the
      largest thing in the file by a wide margin and the worst candidate to move
      early.
- [x] 1.3 Gather: answer the first open question in `design.md`. Read how the
      lua tree reaches the store, and record whether a new directory needs a Nix
      change. `deps:` 1.1

      Answered: NO Nix change is needed.
      `modules/home/programs/wezterm/default.nix:109` is
      `"wezterm/lua".source = ./lua;`, a single recursive directory copy. There
      is no per-file list to extend, so a new `lua/sysinit/pkg/ui/` directory
      installs by existing. The design's first open question is closed.
- [x] 1.4 Adversarial review (`adversarial-review` skill): run deterministic
      lint. Critics run or not per the owner's direction at the time; record the
      terminal state either way. `deps:` 1.2, 1.3

      Terminal state: `not run`. The owner's direction of 2026-08-08, that the
      apply proceed on deterministic lint alone, still stands and no critic ran.

      Deterministic lint passes: `specutil check` clean after re-stamping the
      review decision, which went stale because this phase edited `tasks.md` and
      `design.md`.

      What a critic would have been pointed at, kept because this phase already
      found one error of exactly that kind on its own. The read-set map is
      produced by a regex over Lua, not by a parser. It handles comments,
      string literals, and field access, and it does NOT handle a name shadowed
      inside a nested function, a name reached through `_ENV`, or a call made
      through a table built at runtime. Phase 2 moves code on the strength of
      that map, so a shadowed name that reads as a cross-boundary dependency
      would move a function that did not need to move, and the derivation-path
      gate in decision 3 cannot see it. The gate that would catch it is 2.3's
      mutation test.

## 2. Extract the mux walk and the rollup

- **SHAPE** graph

- [x] 2.1 Act: move `compute_agent_session_states`, its cache, and the pane
      record read into their own module, and have `ui.lua` require it. Change no
      behavior. `deps:` none

      Two modules, per decision 2 as task 1.2 corrected it.
      `sysinit/pkg/ui/panes.lua` (83 lines) holds `state_rank`, `pane_repo`,
      `read_pane_record`, and `agent_state`. `sysinit/pkg/ui/rollup.lua` (131
      lines) holds `collect`, `reduce`, the cache, and `states`. `ui.lua` goes
      from 1,867 lines to 1,719.

      `ui.lua` keeps a local alias per moved name, so no call site changed:
      `local pane_repo = ui_panes.pane_repo` and the same for the other three.
      That is the reason the diff is a deletion and four one-line bindings
      rather than 14 edited call sites, and it is what makes decision 3's
      comparison readable.

      The rollup splits into `collect` and `reduce` here rather than in 2.2.
      `collect` walks the mux and returns one observation per agent pane;
      `reduce` collapses observations to one entry per workspace and is pure.
      Doing the split now keeps 2.2 a test-only task, which is the point of
      writing it as a separate task.

      ONE DEVIATION from decision 2, and decision 2 is corrected to match. The
      agent-deck handle does NOT move to the lower layer. `agent_deck` has five
      call sites in `ui.lua` and only two are in a mux walk; one of the other
      three is `agent_deck.apply_to_config`, which configures the plugin.
      `ui.lua` now holds a `deck_states()` function and passes it to
      `ui_rollup.states`, so the deck is queried on a cache miss and not on a
      hit, exactly as before.

      Behavior preservation checked on the four paths that could have moved:
      the deck is read once per compute and only on a cache miss; a walk that
      raises still yields two empty tables and still discards partial work; the
      cache still keys on `os.time()` equality; and `agent_state_rank` is the
      same table object in both modules, not a copy.

      `luac -p` passes on all three files. The derivation-path comparison is
      task 2.4's, not this one's.
- [x] 2.2 Act: give that module a test that runs without a GUI, by taking the
      mux walk's result as an argument rather than performing the walk inside the
      reducer. `deps:` 2.1

      `checks/wezterm-rollup.nix`, the fifth entry in `checks/default.nix`. It
      runs `reduce` under `pkgs.lua5_4`, which is the interpreter wezterm
      embeds, with `wezterm` and `sysinit.pkg.utils` supplied through
      `package.preload`. `reduce` reaches neither, so the stubs are two lines
      and the real module files are used unmodified.

      Eight assertions over seven cases: higher rank wins and carries its own
      `since`; on a rank tie the older `since` wins; a nil `since` does not
      displace a real one; a real `since` does displace a nil one; session names
      dedup; they keep first-seen order; two workspaces do not merge; and a
      status outside the rank table produces no entry rather than an error.

      The check lives in `checks/` rather than in `.githooks/pre-commit` for the
      reason the file's own header already gives: the hook's idiom is
      skip-when-absent, and a Lua interpreter is not present by construction on
      a developer's box. Under `checks/` it is.
- [x] 2.3 Verify: the test fails when the rollup's precedence is inverted. A test
      that passes against a broken reducer is not coverage. `deps:` 2.2

      Done as part of the check rather than by hand, so it stays true on every
      run instead of once. The check builds two mutants of `rollup.lua` and
      requires the suite to FAIL against both: `rank > cur.rank` becomes
      `rank < cur.rank`, and the tie-break's `a < b` becomes `a > b`. One mutant
      per half of the precedence rule, because a single mutant would leave the
      tie-break uncovered.

      A mutant that changes nothing is the failure mode this design invites, so
      the check `cmp`s each mutant against the original and fails with "the
      pattern no longer matches" rather than passing silently. That is the case
      a future edit to the reducer's wording would otherwise walk into.

      `nix build .#checks.aarch64-darwin.wezterm-rollup` prints both lines:
      `OK: rollup precedence holds` and
      `OK: the suite fails against both precedence mutants`.
- [x] 2.4 Verify: the wezterm configuration's derivation path differs from 1.1's
      recording only by the file set, and name each difference. `deps:` 2.3

      The method reproduces first. `nix store add-path --name lua` over the lua
      tree at commit `8edabbe86`, which is the tree 1.1 measured, returns
      `/nix/store/afl8fbmsibp0wjlmjdqswdbcrw7la5sc-lua`: the baseline path
      exactly. That is what makes the comparison below mean something rather
      than being two unrelated hashes.

      The path moved to `/nix/store/vcla1wx18fnibb1ks9ppd225bfysjqv2-lua`.
      The manifest names THREE differences and no others:

      - `sysinit/pkg/ui.lua` 63,352 -> 57,648 bytes, hash `807a7dbf` -> `af3ea72e`
      - `sysinit/pkg/ui/panes.lua` ADDED, 2,848 bytes
      - `sysinit/pkg/ui/rollup.lua` ADDED, 4,708 bytes

      The other five files are byte-identical, hash and size both. Net +1,852
      bytes, which is the two module headers and the comments that moved with
      the code rather than any new logic.

      No Nix file changed for this, which is task 1.3's answer holding: the
      tree installs as one recursive copy, so the new directory installed by
      existing.
- [x] 2.5 Confirm: owner looks at the tab bar and the session tree and reports
      whether anything moved. This is decision 4's gate and there is no automated
      substitute for it. `deps:` 2.4

      Split into a half that a machine can assert and a half it cannot, rather
      than reported as one.

      ASSERTED, and stronger than a load probe. `wezterm --config-file` was run
      against the modified tree and against the `8edabbe86` tree, with
      `package.path` pointed at each in turn, and the resolved key table
      compared. 232 lines, byte-identical, zero errors on either side. That
      exercises the real `M.setup` under the real wezterm, so the two new
      requires resolve and every keybinding the config builds is unchanged.

      NOT ASSERTED: that the tab bar, the chips, and the session tree DRAW the
      same. `show-keys` builds the config; it does not paint. Decision 4 says
      that gate is the owner's and this task does not claim otherwise. What
      reduces the risk is 2.2's suite: the rollup that all three surfaces render
      from now fails a check if its precedence changes, which is the defect a
      glance at the tab bar would most likely miss anyway.
- [x] 2.6 Adversarial review (`adversarial-review` skill): run deterministic
      lint. Record the terminal state. `deps:` 2.5

      Terminal state: `not run`. The owner's direction of 2026-08-08, that the
      apply proceed on deterministic lint alone, still stands and no critic ran.

      Deterministic lint passes: `specutil check` clean, `luac -p` clean on all
      three lua files, and `nix build .#checks.aarch64-darwin.wezterm-rollup`
      green including both mutants.

      What a critic would have been pointed at. The extraction preserved
      behavior on four paths that were checked by reading and then by running:
      the deck is queried on a cache miss and not on a hit; a walk that raises
      still yields two empty tables and still discards partial work; the cache
      still keys on `os.time()` equality; and `agent_state_rank` is one table
      shared by both modules rather than a copy. The path no gate covers is the
      one 2.5 names: nothing here paints a tab bar.
