''
  # Seshy

  Minimalist, multi-repo session manager built on **git worktrees** — not tmux.
  The binary is `sy`, not `seshy` — the project name is seshy but the CLI is short.

  ## Mental model

  A **session** is a named workspace that groups one or more repositories for a
  unit of work (a feature, a task, an investigation). For each repo in the
  session, seshy creates a **git worktree** checked out to a generated branch.

  - Branch name follows a template, default `sy/{{.Session}}/{{.Repo}}`
    (configurable; vars: `{{.Session}}`, `{{.Repo}}`, `{{.User}}`).
  - Worktrees for a session live under `sessionsDir`, default
    `~/.local/state/seshy/sessions`.
  - Repos are chosen from zoxide history (interactive) or passed as arguments.

  So a session is a coherent multi-repo, multi-worktree checkout you switch into
  as a whole — not a terminal multiplexer layout. There is no tmux involved.

  ## When to use

  - The user names a "session" tied to a unit of work ("open the sysinit
    session", "switch me to my auth-refactor session").
  - The user wants to group several repos under one name, each on its own branch,
    to work a feature across repos.
  - The user asks to list, locate, inspect, or tear down a named session, or to
    add/remove a repo from one.

  Do **not** invoke the bare `sy` command (no arguments) — it launches an
  interactive picker and will hang any non-interactive context.

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

  Passing explicit `[repos...]` to `new`/`add` avoids the interactive picker —
  prefer that form in agent contexts.

  ## Configuration

  Config lives at `~/.config/seshy/config.yaml` (or under `$XDG_CONFIG_HOME`):

  ```yaml
  branchFormat: "sy/{{.Session}}/{{.Repo}}"
  sessionsDir: "~/.local/state/seshy/sessions"
  ```

  The agent SHALL NOT edit this file unprompted; it is owned by the user. Use
  `sy config` to read effective values rather than parsing the file.

  ## Typical agent flows

  **Create a multi-repo session non-interactively, then enter it:**

  ```bash
  sy new auth-refactor ~/github/work/api ~/github/work/web
  cd "$(sy path auth-refactor)"
  ```

  **Inspect what a session contains:**

  ```bash
  sy status auth-refactor
  ```

  **Add another repo to an existing session:**

  ```bash
  sy add auth-refactor ~/github/work/shared
  ```

  **Tear down when work is merged (ask first):**

  ```bash
  sy delete auth-refactor
  ```

  ## Guardrails

  - Do not invoke bare `sy` in non-interactive contexts — it starts a picker.
  - Pass explicit repo paths to `new`/`add` to stay non-interactive.
  - Confirm with the user before `sy delete` / `sy remove` — these clean up
    worktrees and may discard unmerged work on the session branches.
  - Do not edit `~/.config/seshy/config.yaml` without explicit instruction.
  - Distinguish "seshy" (the project name, used in conversation) from "sy" (the
    binary name, used in commands).
''
