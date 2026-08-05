# AGENTS.md

Nix-managed dotfiles for macOS (Apple Silicon) and NixOS, single-user repo.

Scope: facts about **this** repository. Cross-repo rules live in the global
context file that `modules/home/programs/llm/lib/instructions.nix` generates
(`~/.claude/CLAUDE.md`, `~/.config/*/AGENTS.md`). Writing rules live in the
`sysinit-ste` output style. Domain rules live in the skill that owns them. Do
not restate any of those here.

## Stack

- openspec 1.6.0 via `overlays/openspec/`, packaged with the custom
  `spec-driven` schema is the CLI default
- Harness configs all generate from `modules/home/programs/llm/harnesses/`, one
  module per harness: claude-code, codex, copilot, gemini, cursor, opencode, amp,
  crush, devin, goose, pi. A harness owning assets is a directory holding its
  `default.nix` beside them; one with no asset is a single file
- The rest of `modules/home/programs/llm/` splits by role: `lib/` is
  evaluation-time helpers, `runtime/` is the agent-agnostic runtime a harness hook
  executes (notifier, state bus, gates, guard bodies), `skills/` is the scanned
  skill registry, and `subagents/` is the teammate definitions
- ACP adapter commands live in one registry, `lib/acp.nix`, rendered to
  `~/.config/acp/agents.json`. No ACP client is installed yet.
- `hack/` scripts are bash with `set -euo pipefail`, formatted by
  `shfmt -i 2 -ci -sr -s`
- Nix formatter is `nixfmt-rfc-style`

## Commands

```bash
nix develop                     # dev shell: nh, shfmt, shellcheck, lua, jq, fd
nix flake check                 # validate flake (run before commits)
nix fmt                         # format all Nix and .sh files
nix fmt -- --check              # verify formatting, no writes
nh darwin build                 # build current host config (no system change)
nh darwin switch                # apply config to system (use deliberately)
./hack/sync-openspec-schema.sh  # detect drift in the forked openspec schema
./hack/update-pi.sh             # report pi package drift
```

`nh` reaches PATH only after a switch, so run it from `nix develop` on a clean
checkout. `README.md` bootstraps the first switch with `nix run nixpkgs#nh`.

`nix flake check` gates the OpenSpec schema, the citation locks, the
destructive-command guard fixtures, and the parse of every authored fragment.
The parse checks scan broadly, not per-directory: every `.zsh` and `.lua` under
`modules/`, and every shell script in the whole flake source, selected by
shebang as well as by extension. Each also asserts that specific subtrees still
contribute files, so moving one fails loudly instead of dropping coverage.

CI runs `nix fmt -- --check` and `nix flake check` on every push to `main` and
every pull request, plus a `nix eval` of the `lv426` host so the
evaluation-time assertions fire. It evaluates rather than builds: that closure
is 17.9 GiB and a hosted macOS runner has about 14 GB free.

`sy`, `openspec`, and `specutil` are machine-wide. Their own skills carry the
subcommands: `feature-based-session-manager`, `openspec-workflow`, `specutil`.

## Gotchas

- Overlays apply to every host. Gate a Darwin-only workaround on `isDarwin` or
  the Linux build breaks.
- `.sysinit/` is gitignored scratch space. Check `.sysinit/lessons.md` at
  session start.
- `~/.config/git/ignore` already excludes `**/.claude/` and `**/.agents/`. Do
  not repeat those in a per-project `.gitignore`.
- `spec-driven` is not distributed. In a repo shared with others, pin
  `schema: spec-driven`, because a collaborator without the fork gets a "schema
  not found" error.
- Editing a generated dotfile fails: a PreToolUse hook denies writes that
  resolve into `/nix/store`. Edit the Nix source instead.
- `modules/darwin/keybindings.nix` must hold the complete AppleSymbolicHotKeys
  dict, because `defaults write` replaces the whole dict. Read the machine with
  `defaults read com.apple.symbolichotkeys` before you edit that set. A
  downstream flake needs `lib.mkForce` to change an ID the base set defines.
- A spawned helper agent is named per harness: Claude Code says "teammate",
  every other harness says "subagent". Author source text with the `{{agent}}`
  placeholder and let `modules/home/programs/llm/lib/vocab.nix` render it.
