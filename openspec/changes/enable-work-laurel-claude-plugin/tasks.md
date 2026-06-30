# Tasks

## 1. Add the `enabledPlugins` option

- [x] 1.1 In `modules/home/programs/llm/options.nix`, add `enabledPlugins` under `options.sysinit.llm.claudeCode`: `types.listOf types.str`, `default = [ ]`, documented as `<plugin>@<marketplace>` keys for persistent global enable via `settings.enabledPlugins`. Note in the description that it does NOT use `--plugin-dir` and is distinct from the `plugins` option.
- [x] 1.2 Add an `example` showing `[ "laurel-eng@Laurel" ]`.

## 2. Wire it into the settings

- [x] 2.1 In `modules/home/programs/llm/config/claude.nix`, within `programs.claude-code.settings`, conditionally emit `enabledPlugins = lib.genAttrs ccCfg.enabledPlugins (_: true)` only when `ccCfg.enabledPlugins != [ ]` (use `lib.mkIf` or `lib.optionalAttrs` so personal hosts emit no key).
- [x] 2.2 Confirm a personal-host build produces a `settings.json` with no `enabledPlugins` key (diff against pre-change render).

## 3. Fill the work host block

- [x] 3.1 In `hosts/default.nix`, on `Roshan-Bhatia-MacBook-Pro`, set `llm.claudeCode.marketplaces.Laurel = "github/work/pinginc/ai-tooling"`.
- [x] 3.2 Set `llm.claudeCode.enabledPlugins = [ "laurel-eng@Laurel" ]`.
- [x] 3.3 Remove the commented `plugins = [ "code/work/<dirname>/Laurel" ]` placeholder.

## 4. Validate and roll out

- [x] 4.1 `nix flake check` passes.
- [ ] 4.2 On the work host, `nh darwin build` then `nh darwin switch`.
- [ ] 4.3 Verify rendered `~/.claude/settings.json` contains `"enabledPlugins": { "laurel-eng@Laurel": true }` and `known_marketplaces.json` shows `Laurel` as a directory source.
- [ ] 4.4 Launch `claude` in an arbitrary work repo (no flags) and confirm `laurel-eng` is loaded via `/plugin`.
- [ ] 4.5 Stop using the manual `claude --plugin-dir <hm-store-path> …` snippet; confirm the wrapper-injected inline plugin (ast-grep + playwright) still loads without it.
