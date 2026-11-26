# Taskwarrior board

```sh
task-board
task-board --context local --project sysinit
task-board --all --json
task-board --workspaces --all
task-board --all -- +urgent
```

`tb` opens the same board. Use `task-queue` to submit or inspect queued
work. `tq` is its short name.

In the managed Nushell config, both read APIs return structured values:

```nu
tasks board --all --project sysinit | get lanes
tasks queue | select id task? group result
```

Scripts using `nu --no-config-file` can import the same library with
`use ~/.config/nushell/tasks.nu`. Pass board flags as you would to
`task-board`. Both commands leave Taskwarrior and the queue records alone.

The board uses the current Taskwarrior context by default. Inside a repository
with matching tasks, it narrows the view to the repository. `--all` keeps the
context and skips that inference. `--context` applies only to the current
invocation. Taskwarrior filters after `--` pass through to both task queries.

| Key | Action |
| --- | --- |
| `h`, `l` and `j`, `k` | Move between columns and cards |
| `/` and Enter | Filter and open scrollable details |
| `a`, then Ctrl-S | Save an annotation on the selected task |
| `?` | Show key bindings |
| `s` or `b` | Start or stop work, or toggle the manual blocker |
| `v` | Toggle readiness for review |
| `f` | Open the selected task's review in the configured terminal |
| `w` or `o` | Open a linked workspace or queue log |
| `d`, then `y` | Complete a local task |
| `r` and `q` | Refresh and quit |

Taskwarrior owns the lanes. Manual blockers, dependencies, and waiting take
precedence over `+review`. The Review lane contains work explicitly marked
ready for review. Imported Linear tasks keep their original completion
workflow. References and unassigned imports stay out of the board.

Review uses the latest attempt's working directory, a single linked workspace
when available, or the task's absolute `repo` path. `agent-diff` opens a Git
diff against HEAD for a checkout or opens a directory view for a plain
directory. Use an explicit Git base or saved file baseline with
`agent-diff` when you need to compare against an earlier revision or file.

## Hand off a blocked task

1. Record the question with `taskwarrior rc.context:none UUID annotate -- "…"`.
   Include the exact checkout or directory, changes, checks, and the next
   step. Link a local handoff file if it needs more room.
2. Use `taskwarrior rc.context:none UUID modify +blocked -review`, then stop
   the task. A queued worker can exit and release its slot.
3. Annotate the answer on the same UUID, then remove `blocked`. Press Enter
   to read the full handoff or use `taskwarrior rc.context:none UUID info`.
4. Open the recorded workspace with the harness of your choice, or submit an
   explicit retry with `task-queue submit --retry --task UUID --cwd DIRECTORY -- COMMAND`.
   When the work is ready, attach the verification evidence and add `+review`.
   Accept the result through the task's owning workflow.

The JSON view reads the same projection as the TUI. Taskwarrior is the only
required data source. When available, queue data comes from
`task-queue status`, which reads the live queue and stored attempts without rewriting
attempt records. Pass `--workspaces` with `agent-workspace` available to include
workspace links. Both sources join by Taskwarrior UUID. The board stores no
tasks or workflow state of its own.

`task-queue` assigns each new attempt a sequence before submitting it to Pueue.
The board uses that sequence even while a new attempt has no Pueue job ID.
For older attempts, `task-queue` can read the creation times of matching Pueue jobs
and preserve them on reconciliation. The board uses those times when it can
order every older attempt for a task. When the order is uncertain it reports
that uncertainty and omits the attempt link.
Malformed workspace records appear as diagnostics alongside valid links.

See [terminal providers](terminal-providers.md) to configure the same terminal
for the board and queued attempts.
