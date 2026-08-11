> The keywords MUST, MUST NOT, SHOULD, SHOULD NOT, and MAY in this document are
> to be interpreted as described in [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119).

## Why

`openspec/specs/hermes-agent-cli/spec.md` describes a capability no module
implements. Commit `3dd95d8e8` deleted the overlay, the config module, the
`formatForHermes` MCP formatter, and the hermes skill renderer on 2026-07-01,
because the overlay consumed the upstream flake's `default` output. That output
is `minimal` plus 20 extras including `voice`, and `voice` pulls
`faster-whisper` with its wheel-only transitive deps `ctranslate2` and
`onnxruntime` [cite: hermes-default-is-full-with-voice]
[cite: hermes-voice-extra-is-wheel-only]. Every `nh darwin build` therefore
tried to build that stack from source.

Upstream removed `voice` from the `[all]` extra on 2026-05-12 for the same
class of reason, and states the policy in `pyproject.toml`
[cite: hermes-all-excludes-voice]. The flake exposes `minimal` as its own
package output [cite: hermes-minimal-package-output]. The reason for removal no
longer applies to the output this repository should have consumed.

## What Changes

The closest existing pattern is the harness registry at
`modules/home/programs/llm/harnesses/registry.nix`. One entry there reaches
four consumers without a second edit: `harnesses/default.nix` imports the
module, `modules/home/packages.nix` installs `pkgs.${h.package}`,
`runtime/default.nix` derives the label, icon, and notify bridge, and
`lib/instructions.nix` derives the context path and skill-loader answer. This
change reuses all four. Nothing parallel is introduced.

- Add a `hermes` entry to `harnesses/registry.nix` with `package = "hermes-agent"`,
  `context = "~/.hermes/SOUL.md"`, `skillLoader = true`, `ownIcon = false`,
  `notify = "scrape"`, `bridge = null`, and `neovimAdapter = "hermes"`.
  `SOUL.md` in `HERMES_HOME` is the file hermes injects into every session's
  system prompt [cite: hermes-soul-is-global-context], so it holds the shared
  instructions the way `.goosehints` does for goose.
- Add `harnesses/hermes.nix`, following the shape of `harnesses/goose.nix`
  rather than the deleted `config/hermes.nix`. The deleted module carried a
  bespoke `yq` activation script; `sysinit.llm.managedFiles` now accepts
  `format = "yaml"`, so the merge comes from the shared path.
- Add `overlays/hermes-agent.nix`, consuming
  `inputs.hermes-agent.packages.${system}.minimal` and re-wrapping the three
  upstream entrypoints `hermes`, `hermes-agent`, and `hermes-acp`
  [cite: hermes-acp-entrypoint] so the subagent CLIs are on their `PATH`. The
  overlay MUST NOT consume upstream's own `overlays.default`, which aliases
  `packages.default` and is therefore the output that carries `voice`
  [cite: hermes-overlay-is-alias].
- Add the `hermes-agent` flake input with its own `nixpkgs` pinned to a
  revision rather than following this repository's, following the precedent set
  by the `hunk` input in `flake.nix`. No substituter is added; see `design.md`
  for why upstream's Cachix cache is not a route.
- Restore `formatForHermes` in `modules/home/programs/llm/lib/mcp.nix`, deleted
  by `3dd95d8e8`.
- Declare `skills.external_dirs` in the managed config, pointing at
  `~/.claude/skills`, and add no hermes skill renderer. Hermes reads extra skill
  roots from that key [cite: hermes-skills-external-dirs] and treats a directory
  holding a `SKILL.md` as one skill [cite: hermes-skill-dir-holds-skill-md],
  which is the layout `skills/render.nix` already writes. The renderer
  `3dd95d8e8` deleted does NOT come back; see `design.md`.
- Add `modules/home/programs/neovim/config/lua/harness/adapters/hermes.lua`
  following `adapters/goose.lua`, and add `hermes` to the `ORDER` list in
  `harness/registry.lua`.
- Add an assertion in `runtime/default.nix` that every registry
  `neovimAdapter` value names a lua file that exists. The field is declared on
  all 11 current entries and no code reads it, so a registry entry can name an
  adapter that was never written.

### Non-goals

- The `voice`, `wake`, `matrix`, and `messaging` extras. Local speech-to-text is
  the reason the harness was removed and is not restored.
- An ACP route from neovim. `hermes-acp` ships in `minimal` because the `acp`
  extra is a member of `[all]` [cite: hermes-all-extra-membership], and the
  neovim adapter still drives the CLI, not the ACP socket. A separate change
  MAY add the ACP route later.
- The atomic harness. It shares only `harnesses/registry.nix` with this change
  and lands as `add-atomic-harness`.
- Registering hermes as an MCP server in `mcp-servers.nix`. Hermes is a peer
  harness, not a tool of another harness.
- Updating `openspec/specs/hermes-agent-cli/spec.md`. That corpus is history,
  not authority, and the acceptance criteria below replace it.

## Behavior

Must do:
- the darwin closure carries no source-built speech stack, decided by
  `nix build .#darwinConfigurations.lv426.system` exiting 0 and
  `nix-store --query --requisites` over the result matching no store path whose
  name contains `torch`, `faster-whisper`, `ctranslate2`, or `onnxruntime`
- the linux closure carries the same property, decided by
  `nix build .#nixosConfigurations.arrakis.config.system.build.toplevel` and the
  same requisites grep. Upstream supports `x86_64-linux`, `aarch64-linux`, and
  `aarch64-darwin` [cite: hermes-supported-systems], the same set as this
  repository's `cacheSystems`, so no platform guard is needed
- `hermes` resolves from the profile after a switch, decided by `command -v hermes`
  returning a `/nix/store` path and `hermes --version` reporting the version in
  the pinned `pyproject.toml`
- the `acp` entrypoint is present without an extras override, decided by
  `hermes-acp --help` exiting 0
- the wrapper puts the subagent CLIs on `PATH` regardless of the parent
  environment, decided by `env -i PATH=/usr/bin:/bin hermes` resolving
  `claude-code`, `codex`, `opencode`, `copilot`, `gh`, and `gemini` from inside
  a hermes session
- `formatForHermes` renders every unsuppressed catalog server, decided by
  `yq '.mcp_servers | keys' ~/.hermes/config.yaml` listing the same names as the
  catalog minus `suppressedServers`
- the skill library reaches hermes with no second rendered tree, decided by
  `hermes skills list` naming every skill directory under `~/.claude/skills`,
  against a control run with `external_dirs` unset that names none
- the neovim adapter is reachable, decided by
  `nvim --headless -c 'lua assert(require("harness.registry").get_by_name("hermes"))' -c q`
  exiting 0
- a registry entry cannot name an adapter that does not exist, decided by
  setting `neovimAdapter = "nope"` and observing
  `nix build .#darwinConfigurations.lv426.system` exit non-zero with the
  assertion's own message. The flake exposes no `checks` output, so the
  configuration build is the eval gate

Must still hold:
- `nix flake check` exits 0 on the unmodified tree
- an owner-edited `~/.hermes/config.yaml` keeps every key the module does not
  declare in `enforce`, decided by editing one owner key, switching, and diffing
  the file
- activation creates only the paths the module declares, decided by removing
  `~/.hermes`, switching, and listing the directory. No interactive
  `hermes setup` runs
- no credential reaches the store, decided by
  `grep -rIl -e sk-ant -e ANTHROPIC_API_KEY -e refresh_token` over the built
  `hermes-agent` store path returning nothing
- the other 11 harnesses are unchanged, decided by `nix build` on both
  configurations and a `nix store diff-closures` that attributes every added
  path to hermes or its python closure

## Impact

Files changed: `flake.nix`, `flake.lock`, `overlays/default.nix`,
`overlays/hermes-agent.nix`,
`modules/home/programs/llm/harnesses/registry.nix`,
`modules/home/programs/llm/harnesses/hermes.nix`,
`modules/home/programs/llm/lib/mcp.nix`,
`modules/home/programs/llm/runtime/default.nix`,
`modules/home/programs/neovim/config/lua/harness/adapters/hermes.lua`,
`modules/home/programs/neovim/config/lua/harness/registry.lua`.

The change lands in three independently buildable phases: the package (overlay
and flake input), the harness module (registry entry, module, MCP formatter,
skills), and the neovim adapter with its assertion. Each phase is verifiable
with `nix build` alone, so none of them is atomic with another.

The first phase carries a cost the owner should price before it starts.
Upstream classes the Nix install path as best-effort and says it "Breaks often
due to node.js packaging woes" [cite: hermes-nix-path-best-effort], and no
workflow in the pinned tree builds it, so the python venv and the Ink TUI both
build from source on this machine with no substituter to serve them.

Actions that mutate shared state or are hard to reverse:

- `nh darwin switch`. Gated on `nix flake check` and `nix build` exiting 0.
- `nix flake update hermes-agent` writes `flake.lock`. Revertible by `git checkout`.
- The gating signal is `nix build .#darwinConfigurations.lv426.system`, which
  builds the full closure without changing the running system. The kill switch
  is removing the `hermes` registry entry, which drops the module, the package,
  and the icon in one edit.

Judgement that stays with the owner: whether a from-source python and node
build on every input bump is worth the harness, and whether the extras in
`minimal` are the set they want. Build evidence and model critique are not
approval.
