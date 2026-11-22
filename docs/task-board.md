# Taskwarrior board

```sh
task-board
task-board --context local --project sysinit
task-board --all --json
task-board --workspaces --all
task-board --all -- +urgent
```

The board uses the current Taskwarrior context by default. Inside a repository
with matching tasks, it narrows the view to the repository. `--all` keeps the
context and skips that inference. `--context` applies only to the current
invocation. Taskwarrior filters after `--` pass through to both task queries.

| Key | Action |
| --- | --- |
| `h`, `l` and `j`, `k` | Move between columns and cards |
| `/` and Enter | Filter and show details |
| `s` or `b` | Start or stop work, or toggle the manual blocker |
| `w` or `o` | Open a linked workspace or queue log |
| `d`, then `y` | Complete a local task |
| `r` and `q` | Refresh and quit |

The board derives Ready, In Progress, Blocked / Waiting, Review, and Backlog
from Taskwarrior and the latest linked queue attempt. Review means a successful
attempt is available for inspection. Imported Linear tasks keep their original
completion workflow. References and unassigned imports stay out of the board.

The JSON view reads the same projection as the TUI. Queue data comes from
`tq snapshot`, which reads the live queue and stored attempts without rewriting
attempt records. Pass `--workspaces` with `agent-workspace` available to include
workspace links. Both sources join by Taskwarrior UUID. The board stores no
tasks or workflow state of its own.

`tq` assigns each new attempt a sequence before submitting it to Pueue.
The board uses that sequence even while a new attempt has no Pueue job ID.
For older attempts, `tq` can read the creation times of matching Pueue jobs
and preserve them on reconciliation. The board uses those times when it can
order every older attempt for a task. When the order is uncertain it reports
that uncertainty and leaves the task in its Taskwarrior lane.
Malformed workspace records appear as diagnostics alongside valid links.
