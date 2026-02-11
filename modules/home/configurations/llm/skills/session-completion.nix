''
  ---
  name: session-completion
  description: Use when ending a work session, wrapping up a feature, or when the user signals they are done -- ensures all work is committed, pushed, and handed off cleanly
  ---

  # Session Completion

  ## Overview

  Work is NOT complete until `git push` succeeds. This skill defines the mandatory workflow for ending any coding session. Skipping steps leaves work stranded locally.

  ## Mandatory Workflow

  Complete ALL steps below in order:

  ### 1. File Issues for Remaining Work

  Create GitHub issues or beads tasks for anything that needs follow-up. Do not leave undocumented loose ends.

  ### 2. Run Quality Gates

  If code was changed:

  ```bash
  task fmt:all:check    # Verify formatting
  task nix:validate     # Validate flake syntax
  task nix:build:lv426  # Build-time validation
  ```

  Fix any failures before proceeding.

  ### 3. Update Issue Status

  - Close finished work in beads (`bd update <id> --status done`)
  - Update in-progress items with current state

  ### 4. Push to Remote

  This step is MANDATORY and non-negotiable:

  ```bash
  git pull --rebase
  bd sync
  git push
  git status  # MUST show "up to date with origin"
  ```

  ### 5. Clean Up

  - Clear git stashes (`git stash list`, then `git stash drop` as appropriate)
  - Prune remote branches if applicable

  ### 6. Verify

  - All changes committed AND pushed
  - `git status` shows clean working tree
  - Remote is up to date

  ### 7. Hand Off

  Provide context for the next session:
  - What was completed
  - What remains
  - Any blockers or open questions

  ## Critical Rules

  - Work is NOT complete until `git push` succeeds
  - NEVER stop before pushing -- that leaves work stranded locally
  - NEVER say "ready to push when you are" -- YOU must push
  - If push fails, resolve the issue and retry until it succeeds
  - If rebase conflicts occur, resolve them and push
''
