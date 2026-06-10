## 1. Worklog capture hook (`config/worklog.sh`)

- [x] 1.1 Skip non-terminal end reasons: exit early when `reason == "resume"`.
- [x] 1.2 Add seshy detection: if `cwd` is under
  `$HOME/.local/state/seshy/sessions/<name>`, set `kind=seshy-session` and
  `session_name=<name>`.
- [x] 1.3 For a seshy session, enumerate immediate child dirs that are git
  worktrees and build `repos[]` (`repo`/`branch`/`head`/`diffstat` each).
- [x] 1.4 Keep single-repo capture when `cwd` is itself a git worktree
  (`kind=repo`); otherwise `kind=dir`.
- [x] 1.5 Resolve transcript: use stdin path only if it exists on disk, else
  glob `~/.claude/projects/*/<session_id>.jsonl`, else empty.
- [x] 1.6 Add zero-signal guard: no append when no `first_prompt`, no git
  context, and `kind=dir`.
- [x] 1.7 Emit the extended JSON line (`kind`, `session_name`, `repos[]`)
  alongside the existing single-repo fields; preserve the lock-free append.

## 2. Worklog skill (`skills/worklog.nix`)

- [x] 2.1 Update the data-source schema block to document
  `kind`/`session_name`/`repos[]` and the session-id transcript resolution.
- [x] 2.2 Drain step: resolve a missing `transcript_path` via the
  `session_id` glob before falling back to inferred (`~`) summaries.
- [x] 2.3 Compose step: group `seshy-session` entries by `session_name`
  spanning their repos; treat lines without `kind` as single-repo.

## 3. WezTerm tab titles (`pkg/ui.lua`)

- [x] 3.1 Rewrite `format-tab-title` to read `tab.tab_title`,
  `tab.active_pane`, `tab.active_pane.foreground_process_name`,
  `tab.active_pane.current_working_dir`, removing all MuxTab/Pane method calls.
- [x] 3.2 Source the Claude slug input from `tab.active_pane.title`, falling
  back to `tab.tab_title` then cwd basename; keep sparkle + sigil branding.
- [x] 3.3 Confirm the non-Claude branch (explicit title / process-icon + cwd /
  `$HOME`→`~`) still works with field access.

## 4. Validate and roll out (human-verification checkpoints)

- [x] 4.1 `git add` the new/changed files (flakes only see tracked files).
- [x] 4.2 Gating signal: `nh darwin build` passes.
- [ ] 4.3 `nh darwin switch`.
- [ ] 4.4 [HUMAN] End a session inside a seshy session dir → worklog line has
  `kind: seshy-session` + populated `repos[]`.
- [ ] 4.5 [HUMAN] End a session inside a plain repo → worklog line has
  `kind: repo` + real branch/head.
- [ ] 4.6 [HUMAN] Resume a session → **no** new worklog line appended.
- [ ] 4.7 [HUMAN] Open a Claude Code pane in WezTerm → tab shows the slugified
  task summary + sparkle (not cwd basename or default text).
- [ ] 4.8 [HUMAN] Run the `worklog` skill ("what did we accomplish today") →
  seshy work is grouped by session and reads correctly.
