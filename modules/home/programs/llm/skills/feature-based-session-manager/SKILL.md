---
description: Manages feature workspaces, inventories Git worktrees across harnesses, and reduces duplicate checkouts through seshy. Use before creating, grouping, inspecting, archiving, or cleaning worktrees.
allowed-tools: Bash(sy:*)
model: haiku
effort: low
---

# Seshy workspaces

Use `sy` for feature workspaces and Git worktree inventory. A session groups repositories for one unit of work.
Git linked worktrees already share objects and history. Each checkout still has its own files, index, dependencies, and build output.

## Choose ownership first

- Reuse the task's selected worktree. Do not create a second checkout just because a new harness enters the task.
- Give concurrent writers separate worktrees. Shared reference entries are not isolation.
- For terminal-led work, let seshy create and own the feature worktrees. Start the harness inside the selected checkout.
- For app-led work, let Claude Code or Codex own creation, handoff, and cleanup. Inventory these worktrees through Git.
- To group an app-owned worktree, use `sy add <session> <path> --reference`. This creates a reference without copying or moving it.
- App cleanup can remove its worktree and leave a dangling reference. A reference does not extend the app's retention period.
- Do not move app-owned worktrees, rewrite app databases, or replace native worktree hooks to make directory layouts match.
- Do not recursively nest temporary worktrees inside other worktrees. Keep additional isolated work under a named session.

## Create and navigate

Pass repository arguments or `--empty` to avoid the interactive repository picker.
Choose the start point explicitly when the source checkout's HEAD is not the intended base.
Fetch only the needed repository, then select its actual remote branch.

```sh
git -C /path/to/repo fetch origin
sy new feature-name /path/to/repo --start-point origin/main
sy add feature-name /path/to/another-repo --start-point origin/main
sy path feature-name
sy status feature-name --format json
```

For an existing branch:

```sh
sy new feature-name /path/to/repo --existing --branch feature-branch
```

For a read-only collection or externally owned worktree:

```sh
sy new investigation --empty
sy add investigation /path/to/existing-worktree --reference
```

Use `sy current --path --quiet` for workspace lookup. Do not derive session identity from a private path convention.
`sy` with no arguments lists sessions. `sy new` without repositories or `--empty` can invoke the picker.

## Reduce checkout size

Sparse checkout is opt-in. It includes root files and selected directories; omitted files remain in Git history.
Select every directory needed by the task, builds, and tests. Do not enable sparse checkout globally.

```sh
sy new focused /path/to/repo --start-point origin/main \
  --sparse-directory src --sparse-directory tests
```

`--sparse-directory` is repeatable on `new` and `add`. Paths must be directories in the selected commit.
To expand an existing sparse checkout, run `git -C <worktree> sparse-checkout add <directory>`.
To restore a full checkout, run `git -C <worktree> sparse-checkout disable`.

Use package managers' shared download stores and compiler caches. Do not symlink mutable `node_modules`, virtual environments, or build directories across branches.
Do not add Git object alternates to linked worktrees: their object database is already shared.
Do not shallow-clone existing feature work just to save space; missing history changes merge and review behavior.

## Inventory and cleanup preview

```sh
sy worktrees --format json
sy worktrees /path/to/repo --disk-usage --format json
sy prune /path/to/repo --metadata-only --dry-run
```

Without repository arguments, inventory covers the current repository and repositories linked from active and archived seshy sessions.
Explicit arguments restrict the scope. Git registrations reveal worktrees from any harness, regardless of directory location.
Unrelated repositories are not discovered globally; pass them explicitly or register a reference.

Disk measurement is opt-in. Shared Git storage is separate from checkout storage.
Registered nested worktrees are excluded from their parent's checkout size. Symlinks are not followed.
APFS clones and cross-checkout hardlinks can share blocks, so reported checkout sizes are not guaranteed reclaimable totals.

Cautions include dirty/untracked files, detached HEAD, missing upstreams, unpublished commits relative to local upstream refs, missing directories, and locks.
Inventory does not fetch, inspect active processes, or prove that ignored build and recovery files are disposable.
An empty caution list is not deletion permission.

`sy prune --metadata-only` removes only stale Git registrations eligible under Git's lock and expiry rules.
It preserves branches, live worktrees, and dangling references. Dry-run first and inspect the exact actions.
Plain `sy prune` can also delete orphan branches and dangling references; do not substitute it for metadata-only pruning.

## Finish work

- Use `sy archive <name>` to remove a session from the active list while preserving its contents. Archive does not save disk space.
- Use `sy unarchive <name>` to return it to the active list.
- Before `sy delete` or `sy remove`, verify tracked, untracked, ignored, and unpublished work plus active processes and lifecycle ownership.
- Confirm the exact removal scope unless the user has already authorized it. Do not use force flags to bypass a failed safety check.
- App-owned worktrees stay under their app's lifecycle. Use app handoff or permanent-worktree features when work needs to outlive a chat.

## Configuration

`sy config` shows effective settings. Home Manager owns `~/.config/seshy/config.yaml`; edit the Nix source instead of generated files.
Keep post-create hooks explicit and small. Do not automatically install dependencies across every repository in a broad session.

## References

- [Git worktrees](https://git-scm.com/docs/git-worktree)
- [Git sparse checkout](https://git-scm.com/docs/git-sparse-checkout)
- [Codex and ChatGPT desktop worktrees](https://learn.chatgpt.com/docs/environments/git-worktrees)
- [Claude Code worktree hooks](https://code.claude.com/docs/en/hooks#worktreecreate)
