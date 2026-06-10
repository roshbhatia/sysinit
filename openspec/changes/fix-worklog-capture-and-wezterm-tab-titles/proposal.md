## Why

Two recently-shipped features produce wrong output because each reads identity
from the wrong source object.

1. **Cross-session worklog.** The `SessionEnd` hook (`config/worklog.sh`) assumes
   `cwd` is a git repository. In the primary `seshy` workflow `cwd` is the
   *session root* — a container of N nested repo worktrees, not a repo itself —
   so `repo`, `branch`, `head`, and `diffstat` all come back empty and `repo`
   is mis-populated with the session name. It also fires on
   `end_reason: "resume"` (a session *start*, not a completion), trusts the
   stdin `transcript_path` (which on resume points at a uuid whose file does not
   exist, yielding an empty `first_prompt`), and has no guard against appending
   an entry with zero signal. The result is junk index lines.

2. **WezTerm Claude tab titles.** The `format-tab-title` handler
   (`pkg/ui.lua`) calls MuxTab/Pane *methods* (`tab:get_title()`,
   `tab:active_pane()`, `pane:get_foreground_process_name()`,
   `pane:get_current_working_dir()`), but WezTerm passes a `TabInformation`
   *struct* exposing *fields* (`tab.tab_title`, `tab.active_pane`, and on the
   `PaneInformation`: `.title`, `.foreground_process_name`,
   `.current_working_dir`). The first method call throws, the handler aborts,
   and WezTerm renders default tab text — so the slugified Claude title never
   appears (the sparkle only shows via fallback). Even without the throw,
   Claude's task-summary title is the pane OSC title (`active_pane.title`), not
   `tab.tab_title`, so the slugifier had no input.

Both are "derive a human label from runtime context, but query the wrong
object." Fixing them together keeps the one fix per wrong-source-object.

## What Changes

### Worklog capture (`config/worklog.sh` + `skills/worklog.nix`)

- **Filter non-terminal ends.** Skip `end_reason: "resume"` (and any future
  continuation reason) — only record sessions that actually ended.
- **Source identity correctly.** Detect when `cwd` is under
  `~/.local/state/seshy/sessions/<name>`; treat the **session name** as the
  identity and enumerate the immediate child directories that are git worktrees,
  capturing per-repo `repo`/`branch`/`head`/`shortstat`. When `cwd` is itself a
  git worktree, keep today's single-repo capture. Otherwise record a bare dir.
- **Resolve the transcript robustly.** Prefer the stdin `transcript_path` only
  when the file exists; otherwise resolve by globbing
  `~/.claude/projects/*/<session_id>.jsonl`. Record the resolved path (or empty).
- **Zero-signal guard.** Do not append when there is no `first_prompt`, no git
  context, and `cwd` is not a recognized session/repo — nothing worth indexing.
- **Schema additions.** Add `kind` (`seshy-session` | `repo` | `dir`),
  `session_name` (seshy only), and a `repos[]` array (per-repo objects) so the
  skill can render multi-repo sessions. Single-repo entries keep `repo`/
  `branch`/`head`/`diffstat`.
- **Skill update.** Teach `worklog` skill to read `kind`/`repos[]`, resolve a
  missing transcript by `session_id` glob, and group seshy sessions by
  `session_name` (work spanning repos) rather than by a single repo.

### WezTerm tab titles (`pkg/ui.lua`)

- Rewrite the `format-tab-title` handler to read `TabInformation`/
  `PaneInformation` **fields**, not MuxTab/Pane methods:
  `tab.active_pane.foreground_process_name`, `tab.active_pane.title`,
  `tab.active_pane.current_working_dir`, `tab.tab_title`.
- Source the slugifier's input from `active_pane.title` (the OSC-2 pane title
  Claude sets), so `slugify_title` finally receives the task summary.
- Preserve existing behavior: sigil icon + sparkle branding for Claude panes,
  cwd-basename fallback, and the non-Claude shell/process branches.

### Non-goals

- No change to the worklog *report format*, modes, or the Linear/Notion/Slack
  outcomes mapping beyond reading the new schema fields.
- No change to `slugify_title`'s stopword/abbreviation tables or the sparkle
  glyph — only the title's input source and the struct-field access.
- No change to the `SessionEnd` hook's async/lock-free append mechanism.
- No backfill or migration of existing junk lines already in `worklog.jsonl`
  (the skill already dedups by `session_id` and tolerates malformed lines).
- No change to seshy itself or its branch-naming scheme.

## Capabilities

### New Capabilities

- `cross-session-worklog`: The `SessionEnd` capture hook and `worklog` skill
  that index and report work across isolated Claude Code sessions, including
  multi-repo `seshy` sessions.
- `wezterm-tab-titles`: WezTerm per-tab title rendering — process-aware sigil
  icon, Claude task-summary slugification with sparkle branding, and
  cwd/process fallbacks — driven by the `format-tab-title` handler.

### Modified Capabilities

<!-- No pre-existing specs under openspec/specs/ for either; both are new. -->

## Impact

- `modules/home/programs/llm/config/worklog.sh` — rewritten capture logic
  (end-reason filter, seshy detection, multi-repo enumeration, transcript
  resolution, zero-signal guard).
- `modules/home/programs/llm/skills/worklog.nix` — schema doc + drain/compose
  updated for `kind`/`repos[]`/`session_name` and session_id transcript lookup.
- `modules/home/programs/wezterm/lua/sysinit/pkg/ui.lua` — `format-tab-title`
  handler rewritten to struct-field access.
- **Human-verification checkpoints** (encoded in tasks.md):
  - Gating signal: `nh darwin build` must pass before `nh darwin switch`
    (this repo uses `nh darwin`, not `nh os`).
  - After switch: end a session inside a seshy session dir, end one inside a
    plain repo, and *resume* a session — confirm `worklog.jsonl` gets a correct
    entry for the first two and **no** entry for the resume.
  - After switch: open a Claude Code pane in WezTerm and confirm the tab shows
    the slugified task summary plus the sparkle (not the cwd basename or default
    text).
