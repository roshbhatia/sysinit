## Context

`modules/home/programs/llm/config/pi.nix` manages the pi-coding-agent setup. It pre-fetches all pi packages into the Nix store and wires them into `settings.json` via an activation script. Built-in extensions are sourced from a pinned `piExtensionsSrc` fetchFromGitHub and listed in an `extensions = [ ]` array that writes `.ts` files to `~/.pi/agent/extensions/`. npm packages are fetched inline using `fetchNpmPkg` / `buildNpmPkg` helpers and collected in `piPackagesJson`.

The externalEditor keybinding is `ctrl+e`, and `$VISUAL=nvim` is set globally in home-manager. Full nvim with lazy.nvim plugins takes several seconds to start, making it impractical.

## Goals / Non-Goals

**Goals:**
- Wire 7 existing built-in extensions (already in `piExtensionsSrc`) into the active extensions list
- Add `@sysid/pi-vim`, `pi-tool-display`, `pi-subdir-context` as `fetchNpmPkg` derivations
- Add `@psg2/pi-costs` to `home.packages` as a standalone CLI
- Upgrade `piPkgContext` from git fetch → npm v1.1.2
- Add a `nvim-pi` shell wrapper (`nvim --clean -c "set ft=markdown"`) and point pi's externalEditor at it

**Non-Goals:**
- Neovim plugin changes (external repo)
- Adding packages that require runtime npm deps or new lock files
- Changing the subagent or MCP configuration

## Decisions

**nvim-pi wrapper approach**: Pi reads `$VISUAL` or `$EDITOR` for the external editor. Rather than globally changing `$VISUAL` (which would affect other tools), we add a `nvim-pi` script to `home.packages` via `pkgs.writeShellScriptBin` and override the pi-specific `externalEditor` keybinding to invoke it by name. The script calls `nvim --clean -c "set ft=markdown"` for fast, plugin-free startup with markdown filetype set automatically.

**pi-context upgrade**: The git fetch pinned to a specific commit is replaced with `fetchNpmPkg` at v1.1.2. The npm version ships skills that the git version did not include. This is a pure upgrade — same package, better distribution.

**@sysid/pi-vim scoped package**: Follows the existing `@heyhuynhgiabuu/pi-pretty` pattern — `pkgs.fetchurl` with the full scoped tgz URL, or wrapped in `fetchNpmPkg` helper if the helper handles scoped names. Since the helper constructs `https://registry.npmjs.org/${name}/-/${name}-${version}.tgz`, scoped names need the `fetchurl` approach directly (same as `pi-pretty`).

## Risks / Trade-offs

- **piExtensionsSrc rev mismatch**: The 7 new built-in extensions assume the file names exist at the pinned rev (`85d06052fbee...`). Verified: all 7 exist in that commit. When the rev is bumped in future, names should be rechecked.
- **preset extension**: Requires a `~/.pi/agent/presets.json` or `.pi/presets.json` to do anything useful. It's safe to enable without one (it simply adds the commands with no presets available), but full value requires a presets file. Not blocking for initial change.
- **pi-tool-display peer dep**: Requires `@mariozechner/pi-coding-agent@^0.64.0`. The pi-coding-agent version in the overlay should satisfy this; if pi is behind 0.64.0 the extension will load but may not render correctly.
