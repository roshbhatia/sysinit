# decompose-wezterm-ui

## Evidence

Measured on the tree at `make-sysinit-composable`'s archive commit.

| Fact | Value |
| --- | --- |
| `ui.lua` lines | 1,867 |
| `M.setup` span | `:9` to the end of file |
| walks over the mux | 2, `compute_agent_session_states` and `session_tree` |
| readers of the pane record inside the file | 1 function, 2 call sites |
| tests covering any of it | 0 |

`make-sysinit-composable` decision 8 measured 1,799 lines. The file grew during
that change: phase 5 added a viewer and phase 10 added the session names the
rollup displays. Line count is not the thing being reduced here, and saying so
up front stops this change being judged on it.

## Decisions

### 1. `ui.lua` becomes a composition root, not a facade

- Decision: `ui.lua` keeps its name and its `M.setup(config)` entry point, and
  its body becomes requires plus one setup call per extracted module.
- Alternative rejected: a new `ui/init.lua` with `ui.lua` deleted. The file is
  named in the wezterm config's require path and in this repository's own
  documentation, so renaming it spends a rename on no benefit.

### 2. Boundaries follow the data, not the surfaces

- Decision: extract the pane primitives and the rollup first, as TWO layers.
  The lower layer holds what both mux walks read: the agent-deck handle,
  `agent_state_rank`, `pane_repo`, `read_pane_record`, and `pane_agent_state`.
  The upper layer holds `rollup_cache`, `compute_agent_session_states`, and
  `agent_session_states`, and exports only the last of those.
- Alternative rejected: one module per visible surface. The two walks are the
  duplication that matters, and a per-surface split freezes it in place by
  giving each surface its own copy.
- Alternative rejected, and this one was the decision until task 1.2 measured
  it: ONE module holding the rollup and the primitives together, required by
  both the tab bar and the session tree. `session_tree` does not consume the
  rollup. It reads the six primitives and reduces them to a different shape. A
  single module makes the tree require a cache it never reads, which is the
  kind of edge the derivation-path gate in decision 3 cannot see. The read-set
  map in `setup-locals.md` is the evidence; `agent_session_states` is the only
  name in the upper layer that anything outside it reads.

### 3. Behavior preservation is gated by comparison, not by review

- Decision: every extraction step compares the wezterm configuration's
  derivation path against the step before it, and a difference must be explained
  before the step lands.
- Alternative rejected: reading the diff and judging it equivalent. The
  `make-sysinit-composable` baselines exist because that judgment failed there.

### 4. The render gate is owner-run and says so

- Decision: the tab bar, the chips, and the session tree are confirmed by the
  owner looking at them, and the tasks say that plainly rather than claiming an
  automated gate.
- Alternative rejected: asserting the render from the code. That is what
  `make-sysinit-composable` task 10.11 had to record as NOT asserted, and
  repeating the claim here would be the same gap with more confidence.

## Rollout & Gating

One phase per boundary, each landing on its own commit, each gated on the
derivation-path comparison from decision 3. The order runs from the module with
the fewest consumers to the module with the most, so that no step has to be
revisited when a later one moves a shared helper.

The last phase deletes nothing. If a helper survives with no caller, that is a
finding to report rather than a cleanup to fold in silently.

## Risks / Trade-offs

The rendering paths have no automated coverage, so a wrong extraction reaches
the owner as a broken tab bar rather than as a failing check. Decision 4 accepts
that and names who catches it, instead of pretending otherwise.

Splitting closures into modules turns implicit shared state into explicit
arguments. Where the current code reads a local from an enclosing scope, the
split has to decide whether that value is a parameter, a module-level cache, or
a return. Getting one of those wrong is a behavior change that the
derivation-path gate cannot see.

## Adversarial Review

Not run. This change is open and unscoped; there is nothing yet whose failure a
critic could name. The loop runs per phase once the tasks exist, in the shape
`make-sysinit-composable` used.

## Open questions

- ANSWERED by task 1.3. The tree installs as one directory,
  `"wezterm/lua".source = ./lua`, so a new module directory needs no Nix
  change.
- Is one mux walk with two reducers actually cheaper, or does the session tree
  need fields the rollup would then compute on every tick and throw away?
