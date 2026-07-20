# Tasks

## 1. Gate 0 — verify the third-party assumption (no code)

- [ ] 1.1 Verify: from a `tmux -CC new-session`, run `claude --teammate-mode
      tmux`, spawn 2 teammates, and confirm via `wezterm cli list` they appear as
      native WezTerm panes in the ambient session (not a fresh tmux server).
- [ ] 1.2 Verify: press `SUPER+g` and confirm it jumps to a blocked teammate
      pane; confirm the statusline rollup names the worst teammate.
- [ ] 1.3 Confirm: record the exact teammate-mode settings key/shape observed via
      `/config` (e.g. `teamMateMode`) in design.md's Open Questions. If Claude
      spawns its own tmux server, STOP and re-scope this change.

## 2. Deterministic teammate mode (claude.nix)

- [ ] 2.1 Set `teamMateMode = "tmux"` in
      `modules/home/programs/llm/config/claude.nix` alongside the existing
      `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1"` (line 119). Use the exact key
      confirmed in task 1.3.
- [ ] 2.2 Verify: `nix flake check` passes and the rendered Claude settings carry
      the teammate-mode key; `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` is unchanged.
- [ ] 2.3 Confirm: after a later switch, `/config` shows no rejected/unknown key.

## 3. Transparent launcher + tmux profile

- [ ] 3.1 Add a Nix-generated tmux config for the teammate socket (status bar
      off, mouse on, isolated). Follow the module's existing generated-script
      pattern in `modules/home/programs/llm/config/` (e.g. `agent-state.sh`).
- [ ] 3.2 Add the `claude-team` command as a `writeShellScriptBin` wired in
      `modules/home/programs/llm/`, authored per the `shell-script-authoring`
      skill (`set -euo pipefail`, `shfmt -i 2 -ci -sr -s`). It SHALL: require
      `WEZTERM_PANE`; require `tmux`; derive the session name from the repo; run
      `tmux -L claude -f <generated.conf> -CC new-session -A -s <name> 'claude
      --teammate-mode tmux'`.
- [ ] 3.3 Verify: `task fmt:sh:check` passes for the new script; `nix flake
      check` passes.
- [ ] 3.4 Verify: `nh darwin build` succeeds (no system change yet).

## 4. tmux-aware file-bus keying (agent-state.sh)

- [ ] 4.1 In `modules/home/programs/llm/config/agent-state.sh`, name the per-pane
      JSON state file using `TMUX_PANE` when `$TMUX` is set, falling back to the
      current `WEZTERM_PANE` name when `$TMUX` is unset or `TMUX_PANE` is empty.
      Leave the OSC 1337 emit untouched.
- [ ] 4.2 Verify: `task fmt:sh:check` passes; unit-check by running the emitter
      twice with different `TMUX_PANE` values and confirming two distinct files;
      run once with no `$TMUX` and confirm the legacy name is unchanged.

## 5. Rollout

- [ ] 5.1 Verify: `nix flake check` + `nh darwin build` green; review `git diff`
      for the launcher, tmux profile, `claude.nix`, and `agent-state.sh`.
- [ ] 5.2 Apply: `nh darwin switch`.
- [ ] 5.3 Confirm: run `claude-team` on the live system, spawn 2 teammates, and
      confirm native panes + `SUPER+g` jump + two distinct file-bus JSON files.
- [ ] 5.4 Confirm: reverting the change leaves the user's default-socket tmux
      byte-identical (no residual sessions or config).
