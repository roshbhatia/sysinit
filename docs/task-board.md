# Taskwarrior board

```sh
task-board
task-board --context local --project sysinit
task-board --all --json
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
attempt records. Workspaces come from `agent-workspace list`. Both join by the
Taskwarrior UUID. The board stores no tasks or workflow state of its own.
