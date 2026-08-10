## 1. Measure before moving anything

- **SHAPE** graph

- [ ] 1.1 Gather: record the wezterm configuration's derivation path, so every
      later phase has something to compare against. Record it in this folder, in
      the shape `make-sysinit-composable` phase 1 used for its host baselines.
      `deps:` none
- [ ] 1.2 Gather: list every local defined inside `M.setup`, with the set of
      other locals it reads. This is the input to decision 2's boundary, and
      guessing it from function names is how a shared cache ends up duplicated.
      `deps:` 1.1
- [ ] 1.3 Gather: answer the first open question in `design.md`. Read how the
      lua tree reaches the store, and record whether a new directory needs a Nix
      change. `deps:` 1.1
- [ ] 1.4 Adversarial review (`adversarial-review` skill): run deterministic
      lint. Critics run or not per the owner's direction at the time; record the
      terminal state either way. `deps:` 1.2, 1.3

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
