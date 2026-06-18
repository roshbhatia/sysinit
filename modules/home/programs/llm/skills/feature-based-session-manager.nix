''
  # Seshy

  Minimalist, multi-repo session manager built on **git worktrees** — not tmux.
  The binary is `sy`, not `seshy` — the project name is seshy but the CLI is short.

  ## Mental model

  A **session** is a named workspace grouping one or more repositories for a unit
  of work. For each repo, seshy creates a **git worktree** on a generated branch.

  - Branch name follows a template, default `sy/{{.Session}}/{{.Repo}}` (vars:
    `{{.Session}}`, `{{.Repo}}`, `{{.User}}`).
  - Worktrees live under `sessionsDir`, default `~/.local/state/seshy/sessions`.
  - Repos come from zoxide history (interactive) or are passed as arguments.

  A session is a coherent multi-repo, multi-worktree checkout you switch into as a
  whole — not a terminal multiplexer layout. No tmux involved.

  ## Decision routing

  ```
  Have the repo paths?                          -> pass them explicitly to `sy new`/`sy add` (non-interactive)
  Need a session's path / contents?              -> `sy path <name>` / `sy status <name>`
  About to run bare `sy` with no args?           -> do not — it launches an interactive picker and hangs
  About to `sy delete` / `sy remove`?            -> confirm with the user first (discards worktrees)
  ```

  ## Invocation — good vs bad

  ```bash
  # good — explicit args stay non-interactive and safe for agent use
  sy new auth-refactor ~/github/work/api ~/github/work/web
  cd "$(sy path auth-refactor)"
  sy add auth-refactor ~/github/work/shared
  sy status auth-refactor

  # bad
  sy                       # no args -> interactive picker -> hangs any non-interactive context
  sy new auth-refactor     # no repo args -> falls into the picker
  ```

  ## Agent-facing subcommands

  All are non-interactive when given their arguments, and safe for agent use.

  | Command                          | Effect                                                  |
  |----------------------------------|---------------------------------------------------------|
  | `sy new <name> [repos...]`       | Create a session; with repo args, skips the picker      |
  | `sy add <name> [repos...]`       | Add repositories to an existing session                 |
  | `sy list` (alias `sy ls`)        | List all sessions                                       |
  | `sy status [name]` (alias `info`)| Show session details (repos, worktrees, branches)       |
  | `sy path <name>`                 | Print the session directory path (script-safe)          |
  | `sy rename <old> <new>`          | Rename a session                                        |
  | `sy remove <session> <repo>`     | Remove one repo (and its worktree) from a session       |
  | `sy delete [name]` (alias `rm`)  | Delete a session and clean up its worktrees             |
  | `sy config`                      | Show effective configuration                            |
  | `sy config init`                 | Scaffold the config directory with defaults             |
  | `sy config edit`                 | Open the config file in `$EDITOR`                       |
  | `sy init <shell>`                | Print shell-integration code (for `eval` in rc files)   |

  ## Configuration

  Config lives at `~/.config/seshy/config.yaml` (or under `$XDG_CONFIG_HOME`):

  ```yaml
  branchFormat: "sy/{{.Session}}/{{.Repo}}"
  sessionsDir: "~/.local/state/seshy/sessions"
  ```

  Read effective values with `sy config`; do not parse or edit the file. It is
  owned by the user — do not modify it without explicit instruction.

  ## Guardrails

  - Never invoke bare `sy` in a non-interactive context — it starts a picker.
  - Pass explicit repo paths to `new`/`add` to stay non-interactive.
  - Confirm before `sy delete` / `sy remove` — they clean up worktrees and may
    discard unmerged work on the session branches.
  - Distinguish "seshy" (project name, conversation) from "sy" (binary, commands).
''
