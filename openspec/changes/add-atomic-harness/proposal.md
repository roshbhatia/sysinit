> The keywords MUST, MUST NOT, SHOULD, SHOULD NOT, and MAY in this document are
> to be interpreted as described in [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119).

## Why

Atomic is a fork of pi that keeps pi's extension surface: it reads the same
`piConfig` manifest key and defaults its config directory to `.atomic`
[cite: atomic-reads-pi-manifest-key]. It adds a workflow runtime pi does not
have. Adding it as a harness costs one registry entry and an overlay that
parallels `overlays/pi-coding-agent.nix`, because it ships the same shape of
per-platform release tarball [cite: atomic-platform-release-tarballs].

Reusing pi's configuration wholesale breaks on load, and upstream says so.
Atomic bundles forks of four pi packages as always-on builtins, including
`@bastani/subagents` [cite: atomic-bundled-builtin-packages]. Their own comment
records what happens when a second copy of the same package reaches the loader
by a path identity rather than an npm-name identity: dedup is bypassed and the
loader raises `Tool "subagent" conflicts with ...`
[cite: atomic-local-path-tool-conflict].

`modules/home/programs/llm/harnesses/pi/default.nix` installs all 19 pi
packages as absolute `/nix/store` paths. Store paths are exactly the local-path
identity that bypasses dedup. Handing that list to atomic unchanged is a
guaranteed load failure, not a risk.

Atomic also promoted two tools into its core that pi leaves to extensions. Its
core tool set is `read`, `bash`, `edit`, `write`, `find`, `search`, `ls`,
`ask_user_question`, and `todo` [cite: atomic-core-tool-names]. Pi's is `read`,
`bash`, `edit`, `write`, `grep`, `find`, `ls` [cite: pi-core-tool-names]. So
`pi-ask-user` is redundant under atomic, and any config keyed on pi's `grep`
names a tool that does not exist there.

## What Changes

The closest existing pattern is the pi harness: `overlays/pi-coding-agent.nix`
for the package, `modules/home/programs/llm/harnesses/pi/` for the module, and
`modules/home/programs/neovim/config/lua/harness/adapters/pi.lua` for the
editor route. All three are paralleled, not copied wholesale. The single new
mechanism is the exclusion set described below; everything else reuses the
registry consumers named in `readd-hermes-agent-harness`.

- Add four `atomic-coding-agent` entries to `nvfetcher.toml`, one per platform
  asset, following the four `pi-coding-agent` entries already there.
- Add `overlays/atomic-coding-agent.nix`, structurally identical to
  `overlays/pi-coding-agent.nix`, installing `bin/atomic`.
- Add an `atomic` entry to `harnesses/registry.nix` with
  `context = "~/.atomic/agent/AGENTS.md"`, `notify = "hook"`,
  `bridge = ./atomic/extensions/sysinit-notify.ts`, and
  `neovimAdapter = "atomic"`.
- Add `harnesses/atomic/`, whose package list is derived from pi's rather than
  written twice. Introduce `harnesses/shared/pi-packages.nix` holding the
  fetch and build helpers plus the package attribute set that both
  `harnesses/pi/` and `harnesses/atomic/` read.
- Add an exclusion set in `harnesses/atomic/` naming each pi package atomic
  already provides, with the reason on each entry, plus an assertion that fails
  evaluation when an excluded package still appears in the rendered
  `packages` list. Excluded on delivery: `pi-subagents`, `pi-web-access`, and
  `pi-ask-user`.
- Key atomic's `pi-tool-display` config on `search` rather than `grep`, and
  assert that no override key in that config names a tool absent from atomic's
  core set [cite: atomic-core-tool-names].
- Extract `nvimPi` from `harnesses/pi/default.nix` into
  `harnesses/shared/nvim-markdown-editor.nix` so both harnesses point
  `externalEditor` at one derivation. Two modules each declaring their own
  `writeShellScriptBin "nvim-pi"` collide in the profile.
- Set `ATOMIC_SKIP_VERSION_CHECK` in the atomic module. Atomic honors `PI_*`
  names as legacy aliases for its own `ATOMIC_*` variables
  [cite: atomic-honors-pi-env-aliases], so the existing
  `PI_SKIP_VERSION_CHECK` session variable is shared state between two
  harnesses. The atomic module MUST declare its own `ATOMIC_*` name so the
  behaviour does not depend on pi's variable.
- Add `harness/adapters/atomic.lua` driving `atomic --mode rpc --no-session`
  [cite: atomic-rpc-mode-flag], and add `atomic` to `ORDER` in
  `harness/registry.lua`.

### Non-goals

- Atomic's workflow authoring surface. Its `workflow({...})` TypeScript SDK and
  the bundled workflows are usable once the harness exists; declaring workflows
  from Nix is separate work.
- Migrating any pi configuration to atomic. Pi stays configured exactly as it
  is, and both harnesses run side by side.
- Vendoring atomic's own example extensions the way
  `harnesses/pi/vendored-extensions.nix` vendors pi's. The atomic module ships
  only this repository's own extensions until a specific upstream example earns
  a pin.
- The `@bastani/mcp` and `@bastani/intercom` builtins. They load on their own;
  nothing here configures them.
- A stylix theme for atomic. Pi's `stylixThemeAttrs` targets pi's theme schema
  URL, and confirming the fork accepts the same schema is its own task.
- The hermes harness. It shares only `harnesses/registry.nix` and lands as
  `readd-hermes-agent-harness`.

## Behavior

Must do:
- `atomic` resolves from the profile after a switch, decided by
  `command -v atomic` returning a `/nix/store` path and `atomic --version`
  reporting the version in `_sources/generated.nix`
- atomic starts without a tool-registry conflict, decided by
  `atomic -p 'reply with ok'` exiting 0 and its stderr matching no
  `conflicts with` string
- the builtin subagent and web tools are the atomic ones, decided by
  `atomic -p '/help'` output, or the tool list, naming `subagent` and
  `web_fetch` exactly once each
- an excluded pi package cannot reach atomic's settings, decided by removing
  `pi-web-access` from the exclusion set and observing
  `nix build .#darwinConfigurations.lv426.system` exit non-zero with the
  assertion's own message. The flake exposes no `checks` output, so the
  configuration build is the eval gate
- a tool-display override cannot name a tool atomic does not have, decided by
  setting an override key to `grep` and observing the same build fail
- the neovim adapter is reachable and drives rpc, decided by
  `nvim --headless -c 'lua assert(require("harness.registry").get_by_name("atomic"))' -c q`
  exiting 0, and by sending one prompt from a buffer and observing a reply
- atomic and pi keep separate state, decided by
  `atomic` writing only under `~/.atomic` while `~/.pi` is unchanged, checked
  with `find ~/.pi -newermt '-5 minutes'` returning nothing after an atomic
  session

Must still hold:
- pi behaves exactly as before, decided by `pi -p 'reply with ok'` exiting 0 and
  `nix store diff-closures` attributing no change to pi's own package list
- no profile collision, decided by `nh darwin build` exiting 0. Two derivations
  installing `bin/nvim-pi` fail here, so the shared-editor extraction is proven
  by the build itself
- the other 11 harnesses are unchanged, decided by the same closure diff
- `nix build` succeeds on all three of `aarch64-darwin`, `x86_64-linux`, and
  `aarch64-linux`, decided by the per-platform nvfetcher entries resolving. A
  missing platform asset MUST fail with the overlay's own `throw`, matching
  `overlays/pi-coding-agent.nix`

## Impact

Files changed: `nvfetcher.toml`, `_sources/generated.nix`,
`overlays/default.nix`, `overlays/atomic-coding-agent.nix`,
`modules/home/programs/llm/harnesses/registry.nix`,
`modules/home/programs/llm/harnesses/atomic/`,
`modules/home/programs/llm/harnesses/shared/`,
`modules/home/programs/llm/harnesses/pi/default.nix`,
`modules/home/programs/neovim/config/lua/harness/adapters/atomic.lua`,
`modules/home/programs/neovim/config/lua/harness/registry.lua`,
`hack/update-pi.sh`.

The change lands in three independently buildable phases: the shared
extraction from pi's module with pi's behaviour unchanged, the package and
registry entry, then the module with its exclusion assertions and the neovim
adapter. The first phase is a refactor whose success criterion is that nothing
changes, so it MUST ship and build before the second.

Actions that mutate shared state or are hard to reverse:

- `nh darwin switch`. Gated on `nix flake check` and `nh darwin build` exiting 0.
- Editing `harnesses/pi/default.nix` to extract the shared helpers touches a
  working harness. The gate is that pi's rendered `settings.json` is
  byte-identical before and after, and this MUST carry an owner confirmation.
- `nvfetcher` writes `_sources/generated.nix`. Revertible by `git checkout`.
- The kill switch is removing the `atomic` registry entry, which drops the
  module, the package, and the label in one edit.

Judgement that stays with the owner: whether running two pi-lineage harnesses
side by side is worth the shared-state surface that atomic's `PI_*` aliases
create, and whether the exclusion set is the right set. Build evidence and
model critique are not approval.
