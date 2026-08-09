# Does a note reach a running `review --watch`?

No. Run 2026-08-09 against hunk 0.18.0 under WezTerm on aarch64-darwin, with
`sysinit-agent note` as the writer.

Task 3.10 asked this as an experiment rather than a disjunction, and the phase
STOP cites the answer, so this file is the artifact rather than a memory.

## Result

A note written after the viewer starts does not reach it. Observed absent at 5,
15, 30, and 60 seconds, after a focus change into and out of the viewer pane,
and after keystrokes sent to it.

The control fails as well, which is the part that governs how the result is
stated. A tracked-file edit does not reach the running viewer either, so
`--watch` did not auto-reload for any input in this environment. The narrow
claim "the sidecar specifically is not re-read" is therefore NOT supported. The
supported claim is broader and simpler: nothing reaches a running viewer on its
own.

## Why the instrument is trusted

An earlier attempt reported the same absence and was discarded, because an
instrument that fails its own control cannot distinguish "no delivery" from "no
instrument". Three things separate this run from that one.

1. The instrument reads live daemon state, not a cached snapshot. Proof:
   `hunk session reload --repo <path> -- diff` moved the reported diff from
   `+1 -1` to `+3 -3` in the same session. A snapshot could not move.
2. The seed note, written before the viewer started, IS reported by the same
   instrument in the same session. So a positive reading is reachable.
3. `--watch` was on the process command line, read from `ps`, not assumed from
   the wrapper source.

The first attempt of this run was contaminated and thrown away: an explicit
`session reload` issued during the observation dropped the agent context, and
every later reading was zero for that reason rather than for the reason under
test. The run recorded here does no reload until after the observation ends.

## The finding that has no workaround

`hunk session reload -- diff` picks up the working-tree change AND drops the
agent context to zero. So it is not a remedy for a stale note view. It trades a
missing note for no notes at all.

That leaves restarting `review` as the only way to see a note written after the
viewer opened.

## What this contradicts

Task 3.1's probe concluded that `--watch` survives replace-by-rename, because
hunk groups watch targets into parent-directory groups rather than watching the
file. That reading of the source is not what the binary does here. Task 3.1
anticipated exactly this and stated the tie-break: "Task 3.10 asks the same
question through the real writer, so where they disagree, 3.10 governs."

So 3.10 governs. The republish-inside-the-lock design in 3.5 is unaffected and
stays: it is what makes the export correct on disk at all times, which is what
the next `review` reads. Only the claim about a viewer already running is wrong.

## What changed because of this

- `design.md` decision 2 says re-run `review`, rather than claiming a watch
  covers it.
- `sysinit-agent note`'s usage text said "a running `review --watch` picks the
  change up on its own". It said that on the strength of the 3.1 probe. It is
  corrected.

## Not concluded here

Why `--watch` does not fire is not diagnosed, and this change does not need it
diagnosed. It is upstream behavior on one pinned revision. `checks/hunk-agent-context.nix`
pins that revision's `locked.rev` so the next bump fails the check and sends
whoever moves it back to this file.
