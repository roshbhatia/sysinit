## Why

The Laurel work plugin (`laurel-eng`, from the `pinginc/ai-tooling` marketplace) is not persistently enabled on the work machine. It is registered as a github-source marketplace in `known_marketplaces.json`, but `enabledPlugins` is null globally and empty across all 47 projects; the only `installed_plugins.json` record is a stale, project-local `Laurel@Laurel` v1.0.73 (pre-split layout, now `laurel-eng` v1.0.114). So Laurel is effectively off everywhere, and getting it active means a per-project `/plugin install` or an ad-hoc `claude --plugin-dir …`.

Separately, the command run by hand `claude --plugin-dir /nix/store/<hash>-claude-code-hm-plugin --dangerously-skip-permissions …` is redundant: the home-manager `claude` wrapper already injects that exact `--plugin-dir` (the inline ast-grep + playwright MCP plugin). The store hash changes every rebuild, so the saved snippet rots — that is the actual recurring friction, and it has nothing to do with Laurel.

`--plugin-dir` is the documented local-dev override hatch, not a persistence mechanism. The rails for the persistent path already exist (`programs.claude-code.marketplaces` → `extraKnownMarketplaces` + `known_marketplaces.json`); only the global-enable knob (`settings.enabledPlugins`) is missing. The work host is already hostname-gated and `values.llm` already bridges to `sysinit.llm`, so the split between work and personal needs no new conditional.

## What Changes

- Add a `sysinit.llm.claudeCode.enabledPlugins` option (list of `<plugin>@<marketplace>` strings) in `options.nix`, symmetric with the existing `marketplaces` and `plugins` options.
- In `config/claude.nix`, emit `settings.enabledPlugins = { "<plugin>@<marketplace>" = true; … }` only when the option is non-empty. Because the option defaults to empty and only the work host sets it, the key is absent on personal hosts (no new conditional needed).
- In `hosts/default.nix`, fill the work host (`Roshan-Bhatia-MacBook-Pro`) block:
  - `llm.claudeCode.marketplaces.Laurel = "github/work/pinginc/ai-tooling"` — directory source pointing at the maintained local clone (string path, not a Nix path literal, so the work clone is never copied into the store).
  - `llm.claudeCode.enabledPlugins = [ "laurel-eng@Laurel" ]`.
  - Remove the commented `plugins = [ "code/work/<dirname>/Laurel" ]` placeholder; `--plugin-dir` is not the mechanism for Laurel.
- Documentation-only: note that the redundant manual `--plugin-dir <hm-store-path>` is already auto-injected by the wrapper and should be dropped.

### Non-goals

- No change to the home-manager inline plugin (ast-grep + playwright MCP) or the `claude` wrapper — it already auto-loads correctly.
- Not enabling `laurel-biz` or the separate `data-visualizations` marketplace (`laurel-dataviz`); scoped to `laurel-eng` only.
- Not adding a host-gated shell alias for `--dangerously-skip-permissions`/`--ide` (can be a follow-up; out of scope here).
- Not cleaning up the stale `installed_plugins.json` runtime state by hand — superseded once `enabledPlugins` drives enablement.

## Capabilities

### New Capabilities

- `claude-work-plugin-enablement`: Host-gated, declarative enablement of work-only Claude Code marketplace plugins via `sysinit.llm.claudeCode.enabledPlugins` → `settings.enabledPlugins`, so the work machine auto-loads Laurel in every repo while personal hosts stay untouched.

### Modified Capabilities

<!-- No existing spec covers the claudeCode marketplace/plugin options; net-new capability. -->

## Impact

- `modules/home/programs/llm/options.nix` — add `enabledPlugins` option under `sysinit.llm.claudeCode`.
- `modules/home/programs/llm/config/claude.nix` — emit `settings.enabledPlugins` when non-empty.
- `hosts/default.nix` — fill the work host `llm.claudeCode` block; drop the `plugins` placeholder.
- Runtime: `~/.claude/plugins/known_marketplaces.json` and `~/.claude/settings.json` become home-manager-managed read-only symlinks on the work host. The CLI must not be used to toggle these via `/plugin` (consistent with this repo's existing nix-managed-settings stance). Existing live files are backed up via `backupFileExtension = "backup"`.
