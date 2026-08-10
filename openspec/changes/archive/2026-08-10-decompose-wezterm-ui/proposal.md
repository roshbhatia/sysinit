## Why

`modules/home/programs/wezterm/lua/sysinit/pkg/ui.lua` is one file holding every
wezterm-side responsibility this repository has. It is 1,867 lines. `M.setup`
starts at `:9` and runs to the end of the file, so the whole module is one
function body and every helper inside it is a closure over that body's locals.

`make-sysinit-composable` design decision 8 named it the worst file in the
repository, ruled it out of that change because it is not composability, and
sequenced this one after it. That sequencing has now paid: two of that change's
phases removed a responsibility each, so this change starts from a smaller
problem than it would have.

### One function body is why nothing here can be tested

Every helper is a local inside `M.setup`, so nothing in the file is reachable
from outside it. There is no unit test for any of it and there cannot be one
while the shape holds. What that costs is measurable rather than theoretical:
`make-sysinit-composable` task 10.11 had to record the tab-bar half of its
verification as NOT asserted, because the only way to see a chip is to look at a
running tab bar.

### The responsibilities are separable and are already named

The file holds at least these, and they do not share state beyond a colour
table and one cached rollup:

- the pane-state rollup and its cache
- the session tree overlay
- the tab bar and its chips
- the workspace switcher's choices
- the viewer chords
- the appearance and colour derivation
- the quick-select patterns and key tables

### Two walks over the same mux

`compute_agent_session_states` and `session_tree` both iterate every window,
every tab, and every pane, and both now read the same per-pane record file.
They differ in what they reduce to. Neither knows about the other, so a change
to the record schema has two independent readers inside one file.

## What Changes

Split the file into modules with one responsibility each, under
`wezterm/lua/sysinit/pkg/ui/`, keeping `ui.lua` as the composition root that
requires them and calls their setup functions in the current order.

Preserve behavior exactly. This change moves code and draws boundaries. It does
not change what the tab bar shows, which chords exist, or what the rollup
computes.

### Non-goals

- Changing any rendered output. A pixel difference is a defect in this change.
- Adding features, chords, or surfaces.
- Touching the vendored `agent-deck` plugin or its patch.
- Revisiting the session and workspace namespace decisions that
  `make-sysinit-composable` phase 10 settled.
- Moving the neovim configuration, which that change's decision 7 keeps here.

## Behavior

Must do:
- the rendered wezterm configuration is unchanged, decided by comparing the
  derivation path of the wezterm config output before and after
- every extracted module is loadable on its own, decided by requiring each one
  in isolation under luajit with a stubbed `wezterm`
- the rollup has at least one test that does not need a running GUI, decided by
  that test existing and failing when the rollup's precedence is inverted
- `ui.lua` holds no helper definitions, decided by it containing only requires,
  a setup call per module, and the wiring between them
- the mux is walked once per tick rather than twice, or the design states
  plainly why two walks are kept

Must not do:
- change any user-visible string, colour, or chord
- introduce a load-order dependency that is not expressed as an argument or a
  return value

## Impact

Files: `modules/home/programs/wezterm/lua/sysinit/pkg/ui.lua` and the new module
directory beside it. No Nix module changes are expected beyond the file list
that installs the lua tree.

Risk sits in the rendering paths, because they have no automated coverage today.
The derivation-path comparison catches a changed file set and cannot catch a
changed render, so the design owes a gate for the second.
