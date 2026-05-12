## 1. Slice 1 — scaffolding

- [ ] 1.1 Create `modules/home/programs/llm/lib/harness-kit.nix` exposing `mkKit { lib, pkgs, config }` → `{ llmLib, skillsLib, mcpServers, mkInstructions }`. Body wraps the existing three imports (`../instructions.nix` via the `lib`, `../mcp.nix`, `../skills.nix`) and partial-applies `localSkillDescriptions` + `openspecVersion = pkgs.openspec.version` so callers pass only `skillsRoot`.
- [ ] 1.2 Create `modules/home/programs/llm/lib/allowlist.nix` taking `{ lib }`. Move the 149-entry `tierAReadOnlyBash` list from `config/claude.nix` into this file as `tierA`. Add a small `tierB` list with reversible-write patterns: `"git add"`, `"git add *"`, `"git restore --staged *"`, `"nix build *"`, `"nh os build"`, `"nh os build *"`, `"nix fmt"`, `"nix fmt *"`, `"nixfmt *"`, `"nixfmt-rfc-style *"`, `"shfmt -w *"`, `"mkdir -p *"`.
- [ ] 1.3 In `allowlist.nix`, define `formatForClaude tier = builtins.map (cmd: "Bash(${cmd})") tier`. Mirror to other harnesses via stub functions returning identity for now (`formatForCrush`, `formatForCursor`, `formatForGoose`, `formatForAmp`, `formatForOpencode`); each stub gets filled in its slice.
- [ ] 1.4 Update `modules/home/programs/llm/lib/default.nix` to add `harnessKit = import ./harness-kit.nix;` and `allowlist = import ./allowlist.nix { inherit lib; };` to its returned attrset.
- [ ] 1.5 **Verify**: `nix flake check` passes; `nix build .#darwinConfigurations.hyperion.system --no-link` exits 0; `nix eval --raw .#packages.aarch64-darwin.agentsMd` still renders (sanity for the lib export change).
- [ ] 1.6 **Apply**: `git add` lib/ files, commit `feat(llm): scaffold harness-kit and canonical allowlist`, push.
- [ ] 1.7 **Confirm**: `nh darwin switch .` — nothing should change in `~/.claude/` because nothing consumes the new modules yet. `~/.claude/settings.json` `permissions.allow` is byte-identical to its pre-Slice-1 content (captured via `git stash`).

## 2. Slice 2 — claude migration

- [ ] 2.1 In `config/claude.nix`, replace the `llmLib = import ../lib { inherit lib; };` + `skillsLib = import ../skills.nix { inherit pkgs; };` + `defaultInstructions = llmLib.instructions.makeInstructions { ... };` block with `kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; }; instructions = kit.mkInstructions "~/.claude/skills";`.
- [ ] 2.2 In `config/claude.nix`, delete the inline 149-entry `tierAReadOnlyBash` list and `bashAllowEntries`. Replace `settings.permissions.allow = bashAllowEntries;` with `settings.permissions.allow = llmLib.allowlist.formatForClaude llmLib.allowlist.tierA;`.
- [ ] 2.3 **Verify**: `nix flake check` passes; `nh os build .` succeeds; capture pre-refactor `~/.claude/settings.json` via `nix eval --raw .#darwinConfigurations.hyperion.config.home-manager.users.roshan.programs.claude-code.settings`; compare against post-refactor render. Multiset equality on `permissions.allow` (ordering may differ).
- [ ] 2.4 **Apply**: commit `refactor(claude): consume harness-kit and canonical allowlist`, push, `nh darwin switch .`.
- [ ] 2.5 **Confirm**: `~/.claude/settings.json` contains a `permissions.allow` array with the same 149 entries (set equality). wezterm smoke test: `wezterm cli spawn -- claude --version` — captures stdout, confirms version line prints without errors. Then `wezterm cli spawn -- claude` interactively, wait 3 seconds, confirm the TUI loaded and no error text appears in the last 10 lines of output; send `q` or `Ctrl-C` to exit.

## 3. Slice 3 — small-config harnesses

- [ ] 3.1 Migrate `config/codex.nix`: replace the let-block with `kit = llmLib.harnessKit.mkKit { ... }; instructions = kit.mkInstructions "~/.codex/skills";` (or wherever codex's skill root is — verify the existing value).
- [ ] 3.2 Migrate `config/gemini.nix`: same pattern, `skillsRoot = "~/.gemini/skills"` (or the existing value).
- [ ] 3.3 Migrate `config/cursor.nix`: it doesn't use `defaultInstructions`, only `mcpServers`. After migration, the let-block is `kit = llmLib.harnessKit.mkKit { ... }; mcpServers = kit.mcpServers;` — one line shorter than today.
- [ ] 3.4 Migrate `config/copilot-cli.nix`: same as cursor (no instructions, MCP only).
- [ ] 3.5 Migrate `config/aider.nix`: no shared imports today (17 lines). Add a kit-using let-block ONLY if a follow-up needs it; otherwise leave as-is and note in the file that aider has no MCP/skills surface yet (deferred to Phase 2).
- [ ] 3.6 **Verify**: `nix flake check`; `nh os build`; for each migrated harness, render its config to a string via `nix eval --raw` and diff against the pre-refactor capture.
- [ ] 3.7 **Apply**: commit `refactor(llm): migrate small-config harnesses to harness-kit`, push, `nh darwin switch .`.
- [ ] 3.8 **Confirm**: byte-identity on each rendered config file. wezterm smoke: `wezterm cli spawn -- <binary> --version` for each of `codex`, `gemini`, `cursor-agent`, `gh copilot`, `aider` (or appropriate version flag). For TUI ones, also a 3-second-launch-and-quit test.

## 4. Slice 4 — medium-config harnesses + allowlist formatters

- [ ] 4.1 Fill in `allowlist.formatForAmp tier`: returns a list of `{ tool = "Bash"; matches = { cmd = <pattern>; }; action = "allow"; }` entries (one per pattern). Validate the shape against the current amp permissions DSL output.
- [ ] 4.2 Fill in `allowlist.formatForCrush tier`: returns the pattern list as-is (crush's `allowed_tools` is a flat string list).
- [ ] 4.3 Fill in `allowlist.formatForGoose tier`: integrates with the existing `lib/mcp.nix` `formatPermissionsForGoose` (which already converts `*` to `.*` regex). Returns the `shell = { allow = ...; deny = []; }` shape.
- [ ] 4.4 Migrate `config/amp.nix` to consume `allowlist.formatForAmp allowlist.tierA`. The existing inline `permissions` list (the four `git commit`/`git status`/etc. entries) gets replaced; the catch-all `{ tool = "*"; action = "ask"; }` stays.
- [ ] 4.5 Migrate `config/crush.nix` to consume `allowlist.formatForCrush allowlist.tierA`. The existing `allowed_tools` list (`view`, `openspec`, `ls`, `ripgrep`, `fd`, `ast-grep`) merges with the tier-A patterns.
- [ ] 4.6 Migrate `config/goose.nix` to consume `allowlist.formatForGoose allowlist.tierA`. The harness's existing `llmLib.mcp.formatPermissionsForGoose mcpServers.allPermissions` call is replaced.
- [ ] 4.7 **Verify**: byte-identity diff per harness; `nix flake check`; `nh os build`. The amp/crush/goose configs may have ordering differences in the rendered output — accept multiset equality for permission lists.
- [ ] 4.8 **Apply**: commit `refactor(llm): migrate amp/crush/goose to canonical allowlist`, push, `nh darwin switch .`.
- [ ] 4.9 **Confirm**: wezterm smoke for `amp`, `crush`, `goose` — `--version` and 3-second launch test. Verify `~/.config/goose/config.yaml` has the `shell.allow` array, `~/.config/crush/crush.json` has the `permissions.allowed_tools` array, `~/.config/amp/settings.json` has the `amp.permissions` triples.

## 5. Slice 5 — opencode allowlist

- [ ] 5.1 Fill in `allowlist.formatForOpencode tier`: returns an attrset keyed by command name (the part before the `*`) with values `"allow"`. Handle the special case where a tier entry is exact (no `*` suffix) vs prefix (`<cmd>*` → key `<cmd>` matches command `<cmd>` plus any args). The output matches the existing `permission.bash` shape (per-tool allow attrset, glob keys).
- [ ] 5.2 Compare the formatter output against the current ~80-entry inline `permission.bash` block in `config/opencode.nix` for set equality. If the canonical `allowlist.tierA ++ allowlist.tierB` doesn't cover everything opencode currently has, identify the gap entries and choose: (a) add them to `tierA`/`tierB` if generally safe, or (b) keep them as a small inline `extraOpencodeAllow` list in `opencode.nix`. Default: add safe ones to the canonical list; keep opencode-specific ones inline with a comment.
- [ ] 5.3 Migrate `config/opencode.nix` to consume `allowlist.formatForOpencode (allowlist.tierA ++ allowlist.tierB)`. Delete the inline `permission.bash` block.
- [ ] 5.4 **Verify**: byte-identity (multiset on `permission.bash` keys) between pre- and post-refactor render. `nix flake check`; `nh os build`.
- [ ] 5.5 **Apply**: commit `refactor(opencode): migrate to canonical allowlist`, push, `nh darwin switch .`.
- [ ] 5.6 **Confirm**: `~/.config/opencode/opencode.json` has the same `permission.bash` keys as before (set equality). wezterm smoke: `opencode --version`; 3-second launch test.

## 6. Slice 6 — finalize

- [ ] 6.1 Update `AGENTS.md` `## Skills` section if `instructions.nix` changed (it shouldn't have, but re-run `./hack/check-agents-md.sh` to confirm).
- [ ] 6.2 Add a brief paragraph to the openspec change's `design.md` "Migration Plan" section noting any per-harness gotchas discovered during apply (e.g., if opencode had patterns we couldn't safely lift into `tierA`).
- [ ] 6.3 **Verify**: `openspec validate dry-llm-harnesses` exits clean. `./hack/check-agents-md.sh`, `./hack/sync-openspec-skills.sh`, `./hack/sync-openspec-schema.sh`, `./hack/update-pi.sh` all exit clean.
- [ ] 6.4 **Apply**: final commit summarizing the refactor's totals (lines saved, files touched).
- [ ] 6.5 **Confirm**: `openspec archive dry-llm-harnesses --yes`; specs are merged into `openspec/specs/harness-kit/` and `openspec/specs/harness-allowlist/`.

## 7. Final validation

- [ ] 7.1 `nix flake check` green.
- [ ] 7.2 `nh darwin switch .` succeeded after every slice; current live system reflects all slices.
- [ ] 7.3 `~/.claude/settings.json`, `~/.config/{opencode,goose,crush,amp,gemini,copilot-cli,cursor}/...` all render with byte-identity (multiset equality on permission lists) compared to pre-Slice-1 captures.
- [ ] 7.4 wezterm smoke test confirms every touched harness launches without errors after the final `nh darwin switch`.
- [ ] 7.5 `grep -rE "import \\.\\./(lib/instructions|mcp|skills)\\.nix" modules/home/programs/llm/config/ --exclude=pi.nix` returns no matches (the only allowed direct imports are inside `pi.nix`).
- [ ] 7.6 `openspec validate dry-llm-harnesses` exits clean.
- [ ] 7.7 Six scoped conventional commits authored (one per slice + scaffolding), each pushed to main.
