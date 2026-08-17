# AGENTS.md

Nix-managed dotfiles for macOS (Apple Silicon) and NixOS, single-user repo.

Scope: facts about **this** repository. Cross-repo rules live in the global
context file that `modules/home/programs/llm/lib/instructions.nix` generates
(`~/.claude/CLAUDE.md`, `~/.config/*/AGENTS.md`). Writing rules live in the
`sysinit-ste` output style. Domain rules live in the skill that owns them. Do
not restate any of those here.

## Stack

- openspec 1.6.0 via `overlays/openspec/`. The `spec-driven` schema is NOT in
  that overlay. It lives in `modules/home/programs/llm/openspec-schema/`.
  home-manager installs it to openspec's XDG user schema directory, where it
  shadows the built-in. Editing a template rebuilds nothing
- Harness configs all generate from `modules/home/programs/llm/harnesses/`, one
  module per harness. Those are claude-code, codex, copilot, gemini, cursor,
  opencode, amp, crush, devin, goose, and pi. A harness owning assets is a
  directory holding its `default.nix` beside them; one with no asset is a
  single file
- The rest of `modules/home/programs/llm/` splits by role. `lib/` is
  evaluation-time helpers. `runtime/` is the agent-agnostic runtime a harness
  hook executes: notifier, state bus, gates, guard bodies. `skills/` is the
  scanned skill registry, and `subagents/` is the teammate definitions
- ACP adapter commands live in one registry, `lib/acp.nix`, rendered to
  `~/.config/acp/agents.json`. No ACP client is installed yet.
- `hack/` scripts are bash with `set -euo pipefail`, formatted by
  `shfmt -i 2 -ci -sr -s`
- Nix formatter is `nixfmt-rfc-style`
- Custom packages that `cache.nixos.org` never serves are published to
  `roshbhatia.cachix.org`. Its public key is
  `roshbhatia.cachix.org-1:K7Kq2esJYhrV/aCH8Xl7h54y8NULg/k+7WkObNT9VDk=`. The
  token is in the 1Password item "Cachix" and the `CACHIX_AUTH_TOKEN` repo
  secret. The producer is `.github/workflows/build-cache.yml`. It builds the
  `cacheBundle` `symlinkJoin` from `flake.nix` on every push to main touching
  flake, overlays, or `_sources`. Add a package by appending its attr name to
  `cacheAttrs`; a flake-input package goes to `inputPkgsFor`. Over-including is
  harmless, because only genuinely-built paths upload. The consumer substituter
  is declared in `modules/darwin/system.nix` and
  `modules/nixos/common/default.nix`; Lima needs none, it pulls from the host
  store

## Commands

```bash
nix develop                     # dev shell: nh, shfmt, shellcheck, lua, jq, fd
nix flake check                 # validate flake (run before commits)
nix fmt                         # format all Nix and .sh files
nix fmt -- --check              # verify formatting, no writes
ast-grep scan                   # structural lint (reads ./sgconfig.yml)
sgg <path>                      # the same rules against any other repository
nh darwin build                 # build current host config (no system change)
nh darwin switch                # apply config to system (use deliberately)
./hack/sync-openspec-schema.sh  # detect drift in the forked openspec schema
./hack/update-pi.sh             # report pi package drift
```

`nh` reaches PATH only after a switch, so run it from `nix develop` on a clean
checkout. `README.md` bootstraps the first switch with `nix run nixpkgs#nh`.

There is no `checks` flake output. `hack/lint.sh` is the one list of formatters
and linters. It runs ast-grep over the nix source, then `stylua`, `shellcheck`,
the `bootstrap/mise.toml` drift check, `citelock verify`, and `spec-preflight`.
`.githooks/pre-commit` calls it on the staged files, so a violation is a
rejected commit rather than a broken switch. CI calls it with `--all` over the
whole tree. Each tool is skipped when it is absent, so the `nix develop`
shell has to carry `ast-grep`, `stylua`, and `shellcheck`. `hack/` holds nothing
else but the update scripts for the sources nvfetcher does not cover.

The OpenSpec schema, the citation locks, the destructive-command guard
fixtures, and the parse of every authored fragment are evaluation-time
assertions. They live in the module tree, so they fire on `nix eval` of a host,
not on `nix flake check`. The parse checks scan broadly, not per-directory.
They read every `.zsh` and `.lua` under `modules/`, and every shell script in
the whole flake source. Selection is by shebang as well as by extension. Each
also asserts that specific subtrees still contribute files, so moving one fails
loudly instead of dropping coverage.

CI runs `nix fmt -- --check`, `hack/lint.sh --all`, and `nix flake check` on
every push to `main` and every pull request. It also runs a `nix eval` of the
`lv426` host, so the evaluation-time assertions fire. It evaluates rather than
builds: that closure is 17.9 GiB and a hosted macOS runner has about 14 GB
free.

`sy`, `openspec`, and `specutil` are machine-wide. Their own skills carry the
subcommands: `feature-based-session-manager`, `openspec-workflow`, `specutil`.

## Gotchas

- ast-grep reads rules only from `ruleDirs`. An inline `rules:` key in
  `sgconfig.yml` parses as YAML and is then discarded, with no warning.
  ast-grep also never reads XDG and has no config environment variable. It
  finds `sgconfig.yml` by walking up from the working directory. So the global
  library in `modules/home/programs/ast-grep/rules/` is reachable only through
  the `sgg` wrapper. Severity decides gating; `warning` rules report and do not
  fail.
- A `ruleDirs` walk skips a rule file that is itself a symlink, so the module
  installs `ast-grep/rules` as one directory entry. A per-file `xdg.configFile`
  entry, or `recursive = true`, installs every rule and loads none of them, with
  no warning and exit 0. This is the openspec schema gotcha with the halves
  swapped: openspec skips a symlinked *directory* and needs per-file entries.
  The `ast-grep-nix-rules` check carries a known-bad fixture for exactly this.
  A scan that loaded no rules is indistinguishable from a clean one.
- `~/.config/git/ignore` excludes `**/sgconfig.yml` and `ast-grep/`. This repo's
  `.gitignore` negates both. An untracked file is absent from the flake source, so
  forgetting the negation presents as a check that cannot find its own rules.
- Overlays apply to every host. Gate a Darwin-only workaround on `isDarwin` or
  the Linux build breaks.
- An overlay added to work around a broken build goes stale silently. A
  test-skip such as `doCheck = false` or `disabledTests`, or a Tahoe
  `cctools-ld` fix, becomes pure waste once Hydra caches the pristine package.
  The override only perturbs the derivation hash, and forces a local source
  build of something already cached. Audit with the `nix-cache-audit` skill
  before adding one, and keep heavy from-source overrides out of `cacheAttrs`.
- `python313.override { packageOverrides = ... }` pins the whole Python set off
  cache. One test-skip re-hashes every `python313Packages.*`. `openldap` does
  not cascade on Darwin, because curl, git, and python do not link LDAP there.
- To test one override, dry-run the pristine attr at the locked nixpkgs rev:
  `nix build --dry-run "github:NixOS/nixpkgs/<rev>#<attr>"`. "will be fetched"
  means the override is now pure waste. "will be built" means cache never had
  it, so the override costs nothing and can stay.
- `.sysinit/` is gitignored scratch space. Check `.sysinit/lessons.md` at
  session start.
- `~/.config/git/ignore` already excludes `**/.claude/` and `**/.agents/`. Do
  not repeat those in a per-project `.gitignore`.
- This machine's `spec-driven` is a local override. It installs to
  `~/.local/share/openspec/schemas/`, where it shadows the CLI's built-in of
  the same name. A collaborator gets upstream's `spec-driven`, not this one. A
  shared repo then authors against different templates and a different rubric,
  silently, with no error. Nothing warns about that; the names are identical.
- Editing a generated dotfile fails: a PreToolUse hook denies writes that
  resolve into `/nix/store`. Edit the Nix source instead.
- `modules/darwin/keybindings.nix` must hold the complete AppleSymbolicHotKeys
  dict, because `defaults write` replaces the whole dict. Read the machine with
  `defaults read com.apple.symbolichotkeys` before you edit that set. A
  downstream flake needs `lib.mkForce` to change an ID the base set defines.
- A spawned helper agent is named per harness: Claude Code says "teammate",
  every other harness says "subagent". Author source text with the `{{agent}}`
  placeholder and let `modules/home/programs/llm/lib/vocab.nix` render it.

## Harness field footguns

Each one below shipped as a working-looking config that did nothing. None of
them errors; the code no longer carries a comment saying so.

- goose uses `uri`, not `url`, and `type = "streamable_http"` for modern MCP.
  `sse` is legacy and belongs only to a server advertising just `/sse`.
- Antigravity uses `serverUrl`, not `url`, for a remote server.
- Copilot needs an explicit `tools` allowlist on an http server. Omitting it
  exposes no tools rather than all of them; `["*"]` opts in.
- codex needs `experimental_use_rmcp_client = true` or every URL-based MCP entry
  in its TOML is ignored. Its profile files are derived from the profile set,
  never hand-listed. `programs.codex` writes one `<name>.config.toml` per
  profile, so a hand-list breaks on the next rename.
- devin inherits from Cursor, Windsurf, and Claude Code unless its own settings
  are declared. Its behavior then depends on config this repo does not own.
- Amp validates skill frontmatter against a fixed allowlist and errors on any key
  outside it, so it gets its own render. devin and copilot take the Amp render
  for the same reason.
- A vendored pi extension must not write the theme. `ctx.ui.setTheme` persists to
  settings, every declared key is enforced, and the two writers then fight on
  every activation with no message.
- The agentgateway MCP allowlist prefix covers every target behind it. Adding a
  gateway target grants it auto-approval, so that target list is a permission
  surface.

## Verified failure modes with no signal

- `left-alt` chords cannot fire on macOS: WezTerm defaults
  `send_composed_key_when_left_alt_is_pressed` to true, so left-alt composes.
  `modules/darwin/lib/chords.nix` is the shared vocabulary the collision check
  reads. Two layers binding one chord means one wins and the other never fires.
- `wezterm cli` starts a headless `wezterm-mux-server` when it finds no GUI. So
  `wezterm cli spawn` with WezTerm closed prints a pane id, exits 0, and draws
  nothing. The window is real and lives in the daemon until something attaches.
  Every `wezterm cli` call from a window manager, a poller, or a hook therefore
  passes `--no-auto-start`. When `list-clients` is empty, `wezspawn` opens a
  GUI on the `unix` domain rather than spawning.
- A zero-byte state file is what an interrupted first write leaves behind.
  Testing only for existence makes it absorbing. jq on an empty file exits 0 with
  no output, so every later write reports success and stores nothing.
- `git rev-parse --show-toplevel` answers physically, so a relative path reached
  through a symlink reads as outside the repository it is inside. macOS `/tmp` is
  such a symlink, so this is the ordinary case there.
- An unreferenced `let` binding is dropped silently, so a derivation that exists
  only to be checked must be forced from something that ships.
