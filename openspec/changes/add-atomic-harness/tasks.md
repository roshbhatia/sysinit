## 1. Shared extraction

- **SHAPE** graph
- **MERGE** 1.3

- [ ] 1.1 Move pi's npm package attribute set and its `fetchNpmPkg`, `buildNpmPkg`, `mkFetchedNpmPackage`, and `mkBuiltNpmPackage` helpers into `harnesses/shared/pi-packages.nix`, keeping every pinned version and hash byte-identical `writes:` modules/home/programs/llm/harnesses/shared/pi-packages.nix, modules/home/programs/llm/harnesses/pi/default.nix `deps:` none
- [ ] 1.2 Move `nvimPi` into `harnesses/shared/nvim-markdown-editor.nix` and repoint pi's `externalEditor` at it, so one derivation owns `bin/nvim-pi` `writes:` modules/home/programs/llm/harnesses/shared/nvim-markdown-editor.nix, modules/home/programs/llm/harnesses/pi/default.nix `deps:` 1.1
- [ ] 1.3 Build the darwin configuration on the pre-change revision and on this one, then compare the rendered `.pi/agent/settings.json` byte for byte; the refactor is correct only if the two are identical `writes:` none `deps:` 1.1, 1.2
- [ ] 1.4 Adversarial review (`adversarial-review` skill): critics attempt to break the extraction against the proposal `Behavior` criteria; revise until the loop reaches a terminal state (see the skill for the scaled round cap)
- [ ] 1.5 Confirm: the owner accepts that pi's rendered settings are unchanged and that the shared files sit where they want them

## 2. Package

- **SHAPE** graph
- **MERGE** 2.3

- [ ] 2.1 Add four `atomic-coding-agent` entries to `nvfetcher.toml`, one per platform asset, following the four `pi-coding-agent` entries; run `nvfetcher`, then read the resolved version in `_sources/generated.nix` and settle whether it tracks releases or prerelease tags `writes:` nvfetcher.toml, _sources/generated.nix `deps:` none
- [ ] 2.2 Write `overlays/atomic-coding-agent.nix` following `overlays/pi-coding-agent.nix`, installing `bin/atomic` and throwing on an unsupported system, then register it in `overlays/default.nix` `writes:` overlays/atomic-coding-agent.nix, overlays/default.nix `deps:` 2.1
- [ ] 2.3 Build the configuration for each of `aarch64-darwin`, `x86_64-linux`, and `aarch64-linux`, and check that `atomic` appears in the rendered profile `writes:` none `deps:` 2.2
- [ ] 2.4 Adversarial review (`adversarial-review` skill): critics attempt to break the package phase against the proposal `Behavior` criteria; revise until the loop reaches a terminal state

## 3. Harness module and editor route

- **SHAPE** graph
- **MERGE** 3.4

- [ ] 3.1 Add the `atomic` entry to `harnesses/registry.nix` with `context = "~/.atomic/agent/AGENTS.md"`, `notify`, `bridge`, `package`, and `neovimAdapter` filled in per the proposal `writes:` modules/home/programs/llm/harnesses/registry.nix `deps:` none
- [ ] 3.2 Write `harnesses/atomic/` reading the shared package set, carrying an exclusion set with a reason per entry for `pi-subagents`, `pi-web-access`, and `pi-ask-user`, its own `contextHookOrder`, a `pi-tool-display` config keyed on `search`, and `ATOMIC_SKIP_VERSION_CHECK`; add the two assertions that an excluded name cannot reach the rendered list and that no display-override key names a tool outside atomic's core set `writes:` modules/home/programs/llm/harnesses/atomic/ `deps:` 3.1
- [ ] 3.3 Read the `pablopunk/pi.nvim` source to confirm the binary is parameterised by `cmd` on every path it spawns, then write `harness/adapters/atomic.lua` driving `atomic --mode rpc --no-session` and add `atomic` to the `ORDER` list `writes:` modules/home/programs/neovim/config/lua/harness/adapters/atomic.lua, modules/home/programs/neovim/config/lua/harness/registry.lua `deps:` none
- [ ] 3.4 Build both configurations, run the headless neovim check that `get_by_name("atomic")` returns a table, then inject two defects that MUST each fail the darwin build: `pi-web-access` returned to atomic's package list, and a display-override key set to `grep` `writes:` none `deps:` 3.2, 3.3
- [ ] 3.5 Adversarial review (`adversarial-review` skill): critics attempt to break the module and editor phase against the proposal `Behavior` criteria; revise until the loop reaches a terminal state

## 4. Rollout

- [ ] 4.1 Apply: `git push`, then `nh darwin switch` from the `sysinit.laurel` checkout, gated on `nix flake check` and `nh darwin build` exiting 0
- [ ] 4.2 Run the post-switch checks that no build can decide: `atomic -p 'reply with ok'` exits 0 with no `conflicts with` on stderr, the tool list names `subagent` and `web_fetch` exactly once each, `pi -p 'reply with ok'` still exits 0, and `find ~/.pi -newermt '-5 minutes'` returns nothing after the atomic run
- [ ] 4.3 Check that atomic's permission gate is live by running one command the destructive allowlist denies, and confirming atomic refuses it rather than running it
- [ ] 4.4 Confirm: the owner decides whether running two pi-lineage harnesses side by side is worth the shared `PI_*` environment surface, and whether the exclusion set is the set they want
