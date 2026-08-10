# decompose-wezterm-ui

Split modules/home/programs/wezterm/lua/sysinit/pkg/ui.lua into modules with one
responsibility each.

## Where this came from

`make-sysinit-composable` design decision 8 sequences this change after that
one, and task 11.4 opens it. That decision's reasoning, in short: `ui.lua` is
the worst file in the repository, and it is not composability, so it stayed out
of that change. It goes second rather than first because two of that change's
phases reduce it, and doing this first would mean rebasing onto it.

## The starting state, measured after that change landed

- 1,867 lines, with `M.setup` starting at `:9` and running to the end.
- Decision 8 measured 1,799 lines before the change. It grew, because phase 5
  added a viewer and phase 10 added the session names the rollup displays. The
  responsibilities it sheds are not line count.

What that change already removed from it, so this one does not re-litigate:

- Phase 2.3 deleted its user-var write path.
- Phase 5.1 moved its state paths onto the manifest, so it composes no paths of
  its own.
- Phase 10.7 gave it one record read and one render change, and left the
  grouping alone on purpose. `agent-session-rollup` now has a spec covering that
  helper, so its contract is written down before the decomposition starts.

## Open before scoping

- `session_tree` and `compute_agent_session_states` both walk the mux and both
  read pane records. Whether they become one walk with two reducers is the first
  real design question.
- The tab bar, the switcher, and the viewer chords are three consumers with
  three shapes. A module boundary that follows the consumers may not be the one
  that follows the data.
