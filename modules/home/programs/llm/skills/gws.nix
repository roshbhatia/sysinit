''
  # GWS — Google Workspace CLI

  Unified CLI for Google Workspace services (Drive, Gmail, Calendar, Sheets, Docs, etc.).
  Binary: `gws`. Dynamic API discovery means new endpoints work without tool updates.
  All output is structured JSON — pipe to `jq` for filtering.

  ## When to Use

  Use `gws` when the user wants to interact with Google Workspace services from the terminal:

  - Read/write Google Drive files or list folders
  - Send or search Gmail messages
  - Query or update Google Calendar events
  - Read or modify Google Sheets/Docs
  - Any Google Workspace API operation not covered by a dedicated tool

  ## Authentication

  ```bash
  gws auth login          # OAuth browser flow (first-time setup)
  gws auth list           # show active credentials
  gws auth revoke         # revoke a credential
  ```

  Configuration and tokens live in `~/.config/gws/`. Do not edit these files directly.

  ## Command Structure

  ```
  gws <service> <resource> <action> [flags]
  ```

  Examples:

  ```bash
  # Drive
  gws drive files list
  gws drive files get --fileId <id>
  gws drive files create --name "report.txt" --body @./report.txt

  # Gmail
  gws gmail users.messages list --userId me --q "from:boss@example.com"
  gws gmail +send --to user@example.com --subject "Hello" --body "Hi there"

  # Calendar
  gws calendar events list --calendarId primary --timeMin 2026-06-01T00:00:00Z
  gws calendar +agenda          # upcoming events in a readable summary

  # Sheets
  gws sheets spreadsheets create --title "Budget"
  gws sheets spreadsheets.values get --spreadsheetId <id> --range "Sheet1!A1:D10"

  # Docs
  gws docs documents get --documentId <id>
  ```

  ## Helper Commands (+ prefix)

  Prefixed with `+`, these are high-level shortcuts for common workflows:

  | Command               | Effect                                  |
  |-----------------------|-----------------------------------------|
  | `gws gmail +send`     | Compose and send an email interactively |
  | `gws calendar +agenda`| Human-readable upcoming events          |
  | `gws calendar +standup-report` | Summarize yesterday/today meetings |

  ## Flags

  - `--output json` — explicit JSON output (default)
  - `--output table` — tabular output for human reading
  - `--pageSize N` — limit results per page
  - `--fields <mask>` — field mask to reduce response payload
  - `--help` — available on every subcommand

  ## Guardrails

  - Always confirm before sending emails (`+send`) or deleting files — these actions are irreversible.
  - Do not store OAuth tokens outside `~/.config/gws/`; never commit credential files.
  - Prefer `--fields` masks on large list calls to avoid fetching unnecessary data.
  - Confirm the correct Google account is active via `gws auth list` before writing operations.
''
