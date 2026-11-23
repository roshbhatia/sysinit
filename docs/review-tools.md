# Installed review tools

This inventory covers the active macOS workstation's shell, editor, agent,
GitHub, and desktop entry points. It also includes read-only executable
discovery on the remote hosts used by the terminal workflow. Usage frequency
was not measured.

## Patch readers and review UI

| Tool | Installed or configured entry point | Role and current callers |
| --- | --- | --- |
| Reviewr.nvim | `agent-diff --review` | Draft worktree review with file navigation and precise feedback to the originating agent pane. |
| Changes | `changes interactive`, `changes workspace`, `changes note` | Neovim change groups and review notes, a structured snapshot for automation, and durable note storage. |
| Traces | `traces`, `:Traces [session]` | Find local sessions and read assistant replies in Neovim. Structured output and provider commands remain available from the CLI. |
| diffnav | `git diff \| diffnav` | Patch pager with a file tree. Also the external reader for the optional native Changes UI. |
| Hunk and tuicr | `nix shell .#hunk`, `nix shell .#tuicr` | Optional standalone review tools. Set `programs.hunk.enable = true` to install the managed Hunk configuration. |
| Delta 0.20.1 | `git diff \| delta` | Patch and word-level coloring. Installed as a standalone CLI and referenced by diffnav's Nix package. Git has no configured Delta pager. |
| Difftastic 0.72.0 | `difft LEFT RIGHT` | Syntax-aware comparison. Git's configured difftool is Neovim. |
| Git and base utilities | `git diff`, `git show`, `git log -p`, `git range-diff`, `diff`, `sdiff`, `diff3`, `diffstat`, `patch` | Baseline patch, history, and merge plumbing. |
| PR browser | GitHub's Firefox view | The macOS GitHub picker can route back to GitHub for the canonical PR, review, and Actions records. |
| FileMerge and Vim | `opendiff`, Xcode FileMerge, `vimdiff` | macOS/Xcode comparison tools. Separate from the Sysinit viewers. |

## Review local edits

Run `agent-diff --review --allow-directory` from WezTerm to open or focus a
Neovim review split. For a Git worktree, Reviewr includes untracked files
through a temporary Git index and queues comments for explicit delivery.
Run `:ReviewrTurn` before the next agent edit to mark its baseline, then pick
Last turn in Reviewr. Plain directories open the directory browser. Run
the command from the remote shell for a remote checkout.

Run `changes interactive` or `:SysinitChanges` for change groups and durable
notes. Press Enter to open a changed file, `p` for the rendered patch, and `r`
to refresh. Run `traces` or `:Traces` to select a session, or
`traces --session ID` for an exact assistant transcript. Set the corresponding
`sysinit.changes.uiHost` or `sysinit.traces.uiHost` option to `"native"` to
use the standalone interactive UI.

`agents` opens a searchable list of registered agents on the shell's PATH.
Codex, OpenCode, and Claude appear first by default. Selecting an agent
runs its native command in the current pane and directory. Select
**Captured conversations** to open the Atuin thread picker. You can also
open it directly with `agents threads` or `threads`.

```nu
agents
agents pi --continue
agents list --all
agents threads list --style json
ty pane spawn $env.WEZTERM_PANE --direction right --cwd $env.PWD -- agents pi
```

In OpenCode, press `Ctrl-a`, then `d`, to open the native diff from the
conversation. It starts on Last turn with a file tree and one
file's patch. Press `d` inside the viewer to choose a different scope. Use
`/nvim-diff` to open a separate Neovim review split.

For changes since you last reviewed, mark the worktree after reading it.
After the next edit, the command writes a Git patch to stdout.

```sh
review-checkpoint mark
review-checkpoint diff | nvim -c 'setfiletype diff' -
review-checkpoint clear
```

The checkpoint captures the on-disk versions of tracked files and untracked
files Git would add. It preserves the staging area and branch. Each worktree
has one checkpoint, stored as a local Git tree ref. Marking again replaces it.
Diffing keeps the same baseline until you mark again.

## Editor tools

| Tool | Role |
| --- | --- |
| Neovim diff, `git difftool`, and `git mergetool` | Git launches `nvim -d` for selected files and three-way comparisons. |
| Diffview.nvim | Worktree or range review, file history, and merge conflict UI. Neogit, `gh-pr-diff`, `agent-diff`, and the workspace review flow use it. |
| Gitsigns.nvim and Snacks | In-buffer changed lines, blame, hunk navigation, staging, and Git pickers. |
| Neogit | Full Git status and staging workflow inside Neovim. Uses Diffview for diffs. |
| Atlas.nvim | GitHub PR diffs, discussions, review threads, local notes, and review submission. The PR launcher and macOS picker open it. |
| Helix and Emacs | Alternate installed editors with built-in Git changed-line navigation or diff/Ediff. No separate Emacs Magit configuration was found in Sysinit. |
| Mergiraf | Git's configured semantic merge driver. This handles merges for paths that select the driver in attributes. |

## Agent and analysis tools

| Tool | Role |
| --- | --- |
| OpenCode | Native conversation and diff view. `opencode` and `opencode2` resolve to the same executable. The managed Neovim launcher uses `/nvim-diff` so the native `/diff` has its own entry point. |
| Pi | Managed `/diff` extension opens a Neovim split and also exposes agent-callable review tools. The separate Git checkpoint extension supports Pi's fork workflow. Plannotator is installed as a Pi extension for plan review. |
| Codex and Claude Code | Installed native review surfaces. Codex also has an optional App Server adapter that records its reported per-turn patch. The agent registry lists 13 launchable harnesses. |
| `agent-diff` | Opens or refreshes Reviewr with `--review`. Explicit revisions and source links use Diffview. Can compare ordinary folders against a supplied baseline through the workspace path. |
| `agent-workspace` | Optional pane, launch, review, and conversation coordination. Can pin a Git base, refresh the review split, and send notes back to a chosen pane. |
| `ty`, `nuwez`, and `nuvim` | Terminal and editor control. These are the reusable placement and inspection interfaces for ordinary sessions and review splits. |
| `review`, `gate-provider-review-gate`, and `agent-review` | `review` owns the adversarial review ledger consumed by the gate. `agent-review` is a separate session readiness report for dirty, unpushed, or mid-operation repositories. |
| `ast-grep`, `calldiff`, and `git-ai` | Symbol/call-edge analysis and AI attribution. Changes consumes these through providers. Git AI attribution hooks and Traces linkage also have their own consumers. |
| Changes providers | Active manifests for `ast-grep`, `calldiff`, `git-notes`, `local-notes`, and `git-ai`. `changes-provider-codex-review` and `changes-provider-github-pr` are on PATH but did not appear in `changes provider list`. |

## GitHub entry points

- `gh pr view`, `gh pr diff`, `gh pr checks`, `gh pr review`, and `gh run`
  are the native GitHub CLI interfaces.
- `gh dash` is the PR dashboard. Laurel adds a team review queue. `gh enhance`
  is for Actions jobs and logs. Installed extensions also include `gh stack`
  for stack navigation and `gh aw` for agentic workflows.
- `gh-pr-diff` is the shared local launcher. The macOS link picker offers
  Atlas and the browser by default. Put Hunk or tuicr on PATH to use the
  corresponding explicit `gh-pr-diff --tool` backend.
- `gh-pr-state` reads structured PR state and supports bounded, resumable
  polling. The installed GitHub CLI 2.104.0 does not expose `gh event`.
- Changes, GitHub tools and the agent/editor configuration are in the
  shared development profile. The Hammerspoon link picker is Darwin-specific.
  Homebrew had no extra diff or review package in the installed formula and
  cask lists.

## Remote hosts

| Host | Observed commands |
| --- | --- |
| `arrakis` | Hunk, Changes, diffnav, tuicr, Delta, Difftastic, Git AI, calldiff, ast-grep, Neovim, Helix, Emacs, GitHub CLI, `gh-pr-diff`, `agent-diff`, `agent-review`, `review`, `ty`, OpenCode, Codex, Claude Code, Pi, and Mergiraf. |
| `vorgossos` | Neovim, GitHub CLI, OpenCode, and Claude Code were found on the probed PATH and standard Nix profile paths. |
| `lv426` | SSH timed out. The shared workstation profile declares the same review packages as the other managed hosts. |

These checks covered commands on PATH. Editor plugin state, profiles outside
the standard paths, and desktop applications were checked on the local
workstation only.
