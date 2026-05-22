## Why

The pi-coding-agent config has a solid foundation but leaves several high-value built-in extensions unused and is missing a handful of no-dependency npm packages that meaningfully improve the TUI experience. The externalEditor keybinding also opens full nvim (all plugins), making it too slow to use in practice.

## What Changes

- Add 7 built-in extensions from `piExtensionsSrc` to the `extensions` list: `model-status`, `preset`, `trigger-compact`, `input-transform`, `minimal-mode`, `mac-system-theme`, `reload-runtime`
- Add 3 npm packages (no deps, `fetchNpmPkg`): `@sysid/pi-vim`, `pi-tool-display`, `pi-subdir-context`
- Add `@psg2/pi-costs` standalone CLI to `home.packages`
- Upgrade `pi-context` from pinned git fetch → npm v1.1.2 (now ships with skills)
- Add a `nvim-pi` wrapper script that launches `nvim --clean` for the externalEditor keybinding, eliminating plugin-load lag

## Capabilities

### New Capabilities

- `pi-builtin-extensions`: Seven additional built-in extensions wired into the extensions list covering model status/presets, auto-compaction, input macros, minimal mode, theme sync, and hot-reload
- `pi-npm-packages`: Three new npm packages (`@sysid/pi-vim`, `pi-tool-display`, `pi-subdir-context`) and one CLI (`@psg2/pi-costs`) added to the pi package set
- `pi-fast-external-editor`: Wrapper script that makes the externalEditor keybinding fast by bypassing plugin loading

### Modified Capabilities

- `pi-context-upgrade`: `piPkgContext` switches from git fetch (pinned commit) to npm v1.1.2, gaining packaged skills

## Impact

- `modules/home/programs/llm/config/pi.nix` — extensions list, package derivations, piPackagesJson, home.packages, activation script for nvim-pi wrapper
- No overlay changes required (all new packages are npm-fetched within pi.nix)
- No changes to `_sources/` or `nvfetcher.toml` (packages managed inline in pi.nix, not via nvfetcher)
