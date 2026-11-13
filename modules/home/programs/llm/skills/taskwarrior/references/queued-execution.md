## Submit agent work

Use `local-workflows` to distinguish native helpers from separate harness runs.
Native helpers use their harness's API and return results to their coordinator;
they do not need a Pueue attempt for every delegated question.

At task intake, consider queued execution for agreed work that benefits from a
separate harness process, scheduling, or an attachable terminal. Continue work already owned
by the current session here unless a separate execution is useful. A queue is an
execution mechanism; it does not expand authorization or approve external actions.

When installed, `task-queue` records explicit attempts and runs them through Pueue.
Use it instead of a direct `pueue add` for Taskwarrior-linked work. The task must be
pending, unblocked, and have completed dependencies. The queue rechecks this when
execution starts. It rejects duplicate attempts and concurrent task-linked runs
in the same working directory.

1. Read `taskwarrior rc.context:none <uuid> info` and `task-queue status`. Check
   ownership, prior attempts, dependencies, repository, and annotations.
2. Prepare a bounded prompt containing the full UUID, description, relevant
   project and annotations, repository, exact authorization, acceptance criteria,
   and verification requirements. Save it outside disposable temporary storage
   when the attempt must survive a restart. Do not embed credentials.
3. Choose an installed harness and an existing working directory or seshy session.
   Use that harness's supported noninteractive command. Verify flags with `--help`
   when uncertain; do not copy interactive aliases or add permission bypasses.
4. Submit explicit arguments. `--task` uses the task's `repo` by default;
   `--cwd` overrides it and `--session` resolves an existing seshy workspace.
   Choose one of the examples below, not all three for the same task.

```sh
task-queue submit --task <uuid> --cwd /absolute/repository -- \
  goose run --instructions /absolute/task-prompt.md
task-queue submit --task <uuid> --cwd /absolute/repository -- \
  claude --print 'Read /absolute/task-prompt.md and carry out its authorized task.'
task-queue submit --task <uuid> --cwd /absolute/repository -- \
  codex exec 'Read /absolute/task-prompt.md and carry out its authorized task.'
```

Other installed harnesses use the same queue with their own explicit command.
Use `--thread <exact-atuin-id>` to link an attempt to a captured conversation.
Get its full `atuin_id` from `threads list --style json`. This records context;
it does not resume the conversation, infer a thread from its folder, or change
the explicit command. A noninteractive follow-up still needs the harness's
native resume arguments and a bounded prompt.

`task-queue browse` opens an inline picker with `j/k` navigation and `/` search.
Select an attempt to attach its terminal, inspect logs, or inspect its linked
conversation. `task-queue browse --thread <id>` filters by exact conversation ID;
the Threads picker's **Queue attempts** action opens this view. Use
`task-queue thread <attempt-uuid>` to inspect a linked conversation directly.

Add `--terminal` before `--` for an attachable zmx session. Queue output includes
the attempt UUID and Pueue job ID; retain both with the Taskwarrior UUID. A
Taskwarrior session ownership marker remains coordination metadata, not a lock.

Inspect `task-queue status`, `pueue status`, and `pueue log <job-id>`. Use
`task-queue cancel <attempt-uuid>` for cancellation and
`task-queue resume <attempt-uuid>` for an interrupted submission. After a completed
attempt, inspect its result before submitting a new one with `--retry`.

Successful execution sets `review: true` in the attempt record and leaves the
Taskwarrior task pending. Inspect the actual diff, artifacts, and checks; record
verified completion through the task's owning workflow. Imported Linear tasks
still require their authorized Linear completion workflow followed by sync.
