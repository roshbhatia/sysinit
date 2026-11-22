# Installed review tools

This inventory covers the active macOS workstation's shell, editor, agent,
GitHub, and desktop entry points. It also includes read-only executable
discovery on the remote hosts used by the terminal workflow. Usage frequency
was not measured.

## Patch readers and review UI

| Tool | Installed or configured entry point | Role and current callers |
| --- | --- | --- |
| Hunk 0.25.0 | `hunk`, `hunkdiff` | Both names resolve to the same executable. Local worktree and patch review, watch mode, GitHub PRs, saved review sessions, and editor-independent navigation. Sysinit configures the commit-log and viewed-file extensions. The macOS GitHub link picker offers Hunk. |
| Changes 0.13.0 | `changes`, `changes interactive`, `changes workspace` | Diff analysis, structured output, local and committed review notes, and an interactive UI. The PR opener and macOS link picker expose it. Diffview integrations and agent workspaces use its note provider. |
| diffnav 0.13.1 | `git diff \| diffnav` | Patch pager with a file tree. Changes invokes it as its external interactive reader. |
| tuicr 0.29.0 | `tuicr -w`, `tuicr pr` | Local or PR review with persistent viewed state, line comments, and export. The PR opener and macOS link picker expose it. |
| Delta 0.20.1 | `git diff \| delta` | Patch and word-level coloring. Installed as a standalone CLI and referenced by diffnav's Nix package. Git has no configured Delta pager. |
| Difftastic 0.72.0 | `difft LEFT RIGHT` | Syntax-aware comparison. Git's configured difftool is Neovim. |
| Git and base utilities | `git diff`, `git show`, `git log -p`, `git range-diff`, `diff`, `sdiff`, `diff3`, `diffstat`, `patch` | Baseline patch, history, and merge plumbing. |
| PR browser | GitHub's Firefox view | The macOS GitHub picker can route back to GitHub for the canonical PR, review, and Actions records. |
| FileMerge and Vim | `opendiff`, Xcode FileMerge, `vimdiff` | macOS/Xcode comparison tools. Separate from the Sysinit viewers. |

## Editor tools

| Tool | Role |
| --- | --- |
| Neovim diff, `git difftool`, and `git mergetool` | Git launches `nvim -d` for selected files and three-way comparisons. |
| Diffview.nvim | Worktree or range review, file history, and merge conflict UI. Neogit, `gh-pr-diff`, `agent-diff`, and the workspace review flow use it. |
| Gitsigns.nvim and Snacks | In-buffer changed lines, blame, hunk navigation, staging, and Git pickers. |
| Neogit | Full Git status and staging workflow inside Neovim. Uses Diffview for diffs. |
| Octo.nvim and Atlas.nvim | Two Neovim front ends for GitHub PRs and discussions. Both are configured. The PR launcher and macOS picker expose each separately. |
| Helix and Emacs | Alternate installed editors with built-in Git changed-line navigation or diff/Ediff. No separate Emacs Magit configuration was found in Sysinit. |
| Mergiraf | Git's configured semantic merge driver. This handles merges for paths that select the driver in attributes. |

## Agent and analysis tools

| Tool | Role |
| --- | --- |
| OpenCode | Native conversation and diff view. `opencode` and `opencode2` resolve to the same executable. The managed Neovim launcher uses `/nvim-diff` so the native `/diff` has its own entry point. |
| Pi | Managed `/diff` extension opens a Neovim split and also exposes agent-callable review tools. The separate Git checkpoint extension supports Pi's fork workflow. Plannotator is installed as a Pi extension for plan review. |
| Codex and Claude Code | Installed native review surfaces. Codex also has an optional App Server adapter that records its reported per-turn patch. The agent registry lists 13 launchable harnesses. |
| `agent-diff` | Opens or refreshes a Diffview split for an existing WezTerm pane. Can compare ordinary folders against a supplied baseline through the workspace path. |
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
- `gh-pr-diff` is the shared local launcher. Its backends are Neovim/Octo,
  Diffview, Atlas, Changes, Hunk, and tuicr. Both `gh dash` and the macOS GitHub
  link picker compose these through the launcher.
- `gh-pr-state` reads structured PR state and supports bounded, resumable
  polling. The installed GitHub CLI 2.104.0 does not expose `gh event`.
- Hunk, Changes, GitHub tools and the agent/editor configuration are in the
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

## Pruning options

1. Use native OpenCode for last-turn review, Hunk for the live worktree, and
   Diffview for Neovim editing, file history, and merge conflicts. All three
   can work with the agent started normally.
2. Compare Octo and Atlas on one PR with review comments and unresolved
   threads. Retire the weaker backend from the editor, launcher, and link
   picker together. This is the clearest duplicated feature.
3. Compare tuicr's local line-comment export with Hunk's review and note
   workflow before dropping either. Prefer one secondary PR viewer at most.
4. Keep Changes for its structured output and notes. If the standalone
   diffnav workflow goes unused, change the configured external reader and
   verify the patch handoff before removing diffnav. Difftastic and the
   standalone Delta command have no Git difftool or pager binding. Delta
   remains in the Nix closure while diffnav uses it.
5. Keep `agent-workspace` optional. Its conversation binding and automation
   are only needed when someone chooses that workflow. Audit callers before
   removing it, particularly workspace links in Taskwarrior and note export.
   Preserve `ty`, `nuwez`, and `nuvim` as independent interfaces.
