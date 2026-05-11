''
  # Seshy

  Multi-repo tmux session manager. The binary is `sy`, not `seshy` — the project name is seshy but the CLI is short.

  ## When to Use

  Use these subcommands when the user wants to operate on named multi-repo development sessions:

  - The user mentions a "session" with a project name (e.g., "open the sysinit session", "switch me to my work session")
  - The user wants to spawn a persistent dev environment grouping multiple repos under one name
  - The user asks to list, locate, or tear down a named session
  - The user wants to attach a repo to an existing session

  Do **not** invoke seshy for one-shot subprocesses or temporary tmux windows — use `tmux new-session -ds <name> -c <path>` directly for those.

  Do **not** invoke the bare `sy` command (with no arguments). That launches an interactive fzf picker and will hang any non-interactive context.

  ## Agent-Facing Subcommands

  | Command                       | Effect                                                         |
  |-------------------------------|----------------------------------------------------------------|
  | `sy new <name>`               | Create a new named session                                     |
  | `sy add <path>`               | Add a repo path to the current/selected session                |
  | `sy list`                     | List all configured sessions                                   |
  | `sy path <name>`              | Print the canonical path for session `<name>` (script-safe)    |
  | `sy delete <name>`            | Delete the named session                                       |
  | `sy --greedy <name>`          | Fuzzy-match a session name and print its path (script-safe)    |
  | `sy config`                   | Print the effective configuration                              |
  | `sy --version`                | Print version                                                  |
  | `sy --help`                   | Show top-level help; `sy <subcommand> --help` for subcommand help |

  All listed commands are non-interactive and safe for agent use.

  ## Configuration

  Configuration lives at `~/.config/seshy/config.yaml`. It enumerates project directories and discovery depth. The agent SHALL NOT edit this file unprompted; it is owned by the user.

  ## Typical Agent Flows

  **Create a session and attach a repo:**

  ```bash
  sy new my-feature
  sy add ~/github/personal/roshbhatia/sysinit
  sy path my-feature
  ```

  **Look up an existing session's path for a follow-up command:**

  ```bash
  cd "$(sy path my-feature)"
  ```

  **Tear down a session when work is done (ask the user first):**

  ```bash
  sy delete my-feature
  ```

  ## Guardrails

  - Do not invoke the bare `sy` command in non-interactive sessions — it starts an fzf picker.
  - Do not edit `~/.config/seshy/config.yaml` without explicit user instruction.
  - Confirm with the user before `sy delete` — sessions may hold tmux state with unsaved work.
  - Distinguish "seshy" (the project name, used in conversation) from "sy" (the binary name, used in commands).
''
