## Context

Both features shipped in recent commits and are live but wrong. The unifying
defect is identity sourcing: each reads from an object that doesn't hold the
value it wants.

- Worklog: `config/worklog.sh` runs `git -C "$cwd"` against a `seshy` session
  root. Sessions live at `~/.local/state/seshy/sessions/<name>/`; the root is
  not a git repo — it contains one nested worktree per repo on branch
  `dev/roshan/<session>/<repo>`. So all git fields are empty and `repo` falls
  back to the session name. The hook also fires on `end_reason: "resume"` and
  trusts a stdin `transcript_path` that, on resume, names a uuid with no file.
- WezTerm: `format-tab-title` receives a `TabInformation` struct (verified
  against wezterm.org docs), not a MuxTab. The handler's first line,
  `tab:get_title()`, is a method call that the struct doesn't answer → the
  handler throws → default rendering. The slug's intended input is the pane OSC
  title, `tab.active_pane.title`.

## Goals / Non-Goals

**Goals:**
- Worklog index lines carry real identity for both plain-repo and seshy
  multi-repo sessions, and never record continuation (`resume`) events or
  zero-signal noise.
- The `worklog` skill resolves transcripts by `session_id` when the recorded
  path is stale, and reports seshy work grouped by session across repos.
- WezTerm Claude tabs render the slugified task summary + sparkle reliably;
  non-Claude tabs keep the process-icon + cwd behavior.

**Non-Goals:**
- Redesigning the report format, modes, or outcome-mapping logic.
- Tuning the slug stopword/abbreviation tables.
- Migrating or deleting existing junk lines in `worklog.jsonl`.

## Decisions

### Identity is the seshy session, not a repo

When `cwd` is under `$HOME/.local/state/seshy/sessions/<name>`, the unit of work
is the **session** (which spans repos), so:

```
kind = "seshy-session"
session_name = <name>
repos = [ {repo, branch, head, diffstat} for each immediate child
          of the session root that is a git worktree ]
```

The skill then groups seshy entries by `session_name`. A plain git `cwd` stays
single-repo (`kind = "repo"`); anything else is `kind = "dir"`.

```
            cwd
             │
   ┌─────────┴───────────────────────────────┐
   │ under ~/.local/state/seshy/sessions/<n>? │
   └─────────┬───────────────────────┬────────┘
            yes                       no
             │                        │
   kind=seshy-session         is cwd a git worktree?
   session_name=<n>            ┌──────┴───────┐
   repos=[per worktree]       yes             no
                          kind=repo        kind=dir
                          (repo/branch/    (basename only,
                           head/diffstat)   gated by signal)
```

### Skip continuation end-reasons, guard zero-signal

Only terminal reasons produce a line. `resume` is explicitly skipped. After
context gathering, if there is no `first_prompt`, no git context, and
`kind = "dir"`, skip the append entirely — an empty line is worse than none.

### Transcript resolution is by session_id, with the stdin path as a hint

```
if stdin transcript_path exists on disk → use it
else → glob ~/.claude/projects/*/<session_id>.jsonl, newest match
else → "" (skill degrades: synthesize from first_prompt/diffstat, marks "~")
```

This decouples capture from the resume path-fork. `session_id` is the stable
key the skill already dedups on.

### WezTerm: read struct fields, source title from the active pane

`format-tab-title(tab, ...)` gives `TabInformation`. Replace every method call:

| Old (method, throws)                 | New (struct field)                       |
|--------------------------------------|------------------------------------------|
| `tab:get_title()`                    | `tab.tab_title`                          |
| `tab:active_pane()`                  | `tab.active_pane`                        |
| `pane:get_foreground_process_name()` | `tab.active_pane.foreground_process_name`|
| `pane:get_current_working_dir()`     | `tab.active_pane.current_working_dir`    |

Claude's task-summary title comes from the pane OSC title, so the slugifier's
input is `tab.active_pane.title` (fall back to `tab.tab_title` then cwd
basename). `current_working_dir` is a Url userdata — keep the existing
`.file_path` extraction. The sigil/ribbon branding path is unchanged.

## Risks / Trade-offs

- **Schema evolution.** Adding `kind`/`repos[]` means old lines lack them; the
  skill must treat their absence as `kind = "repo"`. Accepted — the skill
  already parses defensively and we own both ends.
- **Worktree enumeration cost.** Iterating session children runs a `git`
  probe per child at `SessionEnd`. Sessions hold a handful of repos and the
  hook is `async = true`, so the cost is off the critical path.
- **PaneInformation field availability.** `.current_working_dir`/`.title` exist
  on `PaneInformation` in current WezTerm (WebGpu build in this config); if a
  field is nil the existing fallbacks cover it. Low risk.
- **Stale transcript glob miss.** If `~/.claude/projects/*/<session_id>.jsonl`
  is pruned, the skill degrades to inferred summaries (already specified). No
  hard failure.
