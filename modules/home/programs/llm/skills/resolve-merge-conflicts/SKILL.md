---
name: resolve-merge-conflicts
description: Inspect and resolve Git conflicts when a merge, rebase, cherry-pick, or stash apply leaves unmerged paths. Start with Git index stages and inspect compact diffs for one path at a time.
---

# Resolve merge conflicts

1. Inspect `git status` in the selected checkout to identify the operation and
   preserve unrelated work. From that checkout, run the helper at this skill's
   absolute path, for example
   `nu --no-config-file /path/to/resolve-merge-conflicts/scripts/conflicts.nu`.
2. Use `--file 'path/from/repository/root'` to compare the staged versions.
   Stage 1 is the base, stage 2 is the current integration side, and stage 3
   is the incoming side. During a rebase the incoming side is the commit being
   replayed. Read the relevant commits and nearby code when the hunks alone
   cannot establish intent.
3. Resolve each path according to the intended behavior of both sides. For an
   add/delete, symlink, or submodule conflict, inspect the blob or commit
   identified by the index before choosing the result. Stage only the resolved
   paths. Continue the existing Git operation when it falls within the
   authorized work.
4. Run `git diff --name-only --diff-filter=U` and `git diff --cached --check`,
   then verify the affected behavior with the repository's checks.

The helper reads Git's index and emits JSON. Its detailed output shows a bounded
preview from stage 2 to stage 3 when both are regular files.

Adapted from [Warp's conflict workflow](https://github.com/warpdotdev/common-skills/blob/8792394ff1b655e0af451b8fabb68ef0cfcbd208/.agents/skills/resolve-merge-conflicts/SKILL.md).
