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

- [ ] 2.1 Act: move `compute_agent_session_states`, its cache, and the pane
      record read into their own module, and have `ui.lua` require it. Change no
      behavior. `deps:` none
- [ ] 2.2 Act: give that module a test that runs without a GUI, by taking the
      mux walk's result as an argument rather than performing the walk inside the
      reducer. `deps:` 2.1
- [ ] 2.3 Verify: the test fails when the rollup's precedence is inverted. A test
      that passes against a broken reducer is not coverage. `deps:` 2.2
- [ ] 2.4 Verify: the wezterm configuration's derivation path differs from 1.1's
      recording only by the file set, and name each difference. `deps:` 2.3
- [ ] 2.5 Confirm: owner looks at the tab bar and the session tree and reports
      whether anything moved. This is decision 4's gate and there is no automated
      substitute for it. `deps:` 2.4
- [ ] 2.6 Adversarial review (`adversarial-review` skill): run deterministic
      lint. Record the terminal state. `deps:` 2.5
