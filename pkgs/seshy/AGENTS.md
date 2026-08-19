# Agent context for seshy

Read this before changing anything under `pkgs/seshy/`.

## What this is

A local Go CLI that manages named, multi-repo work sessions on top of git
worktrees. It does no network I/O. The project is `seshy`; the binary is `sy`.

It was a standalone repository (`roshbhatia/seshy`) until 2026-08-18, when it
was vendored here and the upstream was archived. Build it with the sysinit
flake, not with a Taskfile or a nested `nix develop`.

## Repository map

```
main.go           entry point: calls cmd.Execute
cmd/              cobra command tree; every verb is wired here
internal/
  config/         config.yaml under XDG, merged over defaults
  hook/           runs the postCreate, postAdd, and preDelete commands
  session/        session directory, repo attachment, worktrees, archive
  tmpl/           branch-name template, over {{.Session}} {{.Repo}} {{.User}}
```

Shared code lives one level up, in `pkgs/internal/`. `paths` resolves XDG and
the sysinit manifest, `git` runs git, and `ui` holds the ANSI output this tool
used to own. Read `pkgs/AGENTS.md` before changing any of them.

## Mental model

A session is a named directory holding one entry per attached repository. For a
git repository, seshy creates a worktree on a generated branch. For a plain
directory, it creates a symlink, and `sy status` marks the entry `(symlink)`.

Archiving moves a session to `archiveDir` and repairs the main repos so they
track the new location. It destroys nothing, so it does not prompt.

## Commands

| Command | Description |
|---------|-------------|
| `sy new <name>` | Create a session, selecting repos from zoxide history |
| `sy new <name> --empty` | Create a session with no repositories |
| `sy add <name>` | Add repositories to an existing session |
| `sy list` / `sy ls` | List sessions |
| `sy list --archived` | List archived sessions |
| `sy archive <name>` | Move a session into the archive |
| `sy unarchive <name>` | Restore an archived session |
| `sy delete <name>` / `sy rm <name>` | Delete a session, its worktrees, and its branches |
| `sy delete --archived <name>` | Delete an archived session |
| `sy path <name>` | Print a session path |
| `sy status` | Show the repos in a session |
| `sy config` | Show the effective configuration |
| `sy --greedy <query>` | Fuzzy match a session and print its path |

`sy` with no arguments opens the interactive picker. It is human-only. An agent
uses the subcommands above; the `feature-based-session-manager` skill states
this rule.

## Configuration

Nix owns the config. `modules/home/programs/seshy/default.nix` generates
`~/.config/seshy/config.yaml`, and sets `branchFormat`, `sessionsDir`, and the
`postCreate` hooks. Edit that module, not the generated file. `sy config edit`
opens a file home-manager overwrites on the next switch.

`sessionsDir` comes from `config.sysinit.paths.resolved.seshySessions`, which
is the same value `pkgs/internal/paths` reads back under
`SeshySessionsKey`. Change one and change the other.

## Version

`cmd/root.go` holds `const version`, which `sy --version` prints. The store
path no longer carries it, because `overlays/sysinit-gotools.nix` builds every tool
under one version.

## Build

`overlays/sysinit-gotools.nix` builds the binary as `seshy` and exposes it as `sy`,
because every caller invokes `sy`. The unit tests shell out to `git`, so `git`
stays in that derivation's `nativeCheckInputs`.
