## 1. Slice 1 — scaffolding

- [x] 1.1 Created `modules/home/programs/llm/lib/harness-kit.nix` exposing `mkKit { lib, pkgs, config }` → `{ llmLib, skillsLib, mcpServers, mkInstructions }`.
- [x] 1.2 Created `modules/home/programs/llm/lib/allowlist.nix` taking `{ lib }`. Moved the 149-entry `tierAReadOnlyBash` list into this file as `tierA`. Added 14-entry `tierB` (reversible writes: `git add`, `nix build`, `nix fmt`, `shfmt -w`, `mkdir -p`, etc.).
- [x] 1.3 Implemented `formatForClaude`, `formatForCursor`, `formatForCrush`, `formatForAmp`, `formatForGoose`, `formatForOpencode`. Each maps tier patterns to its harness-native shape.
- [x] 1.4 Updated `lib/default.nix` to re-export `harnessKit = import ./harness-kit.nix;` and `allowlist = import ./allowlist.nix { inherit lib; };`.
- [x] 1.5 **Verify**: `nix build .#darwinConfigurations.hyperion.system --no-link` green; `nix eval` confirms tierA count is 149 and formatters produce expected shapes.
- [x] 1.6 **Apply**: committed `feat(llm): scaffold harness-kit and canonical allowlist`, pushed.
- [x] 1.7 **Confirm**: nothing consumes the new modules yet — `~/.claude/settings.json` unchanged.

## 2. Slice 2 — claude migration

- [x] 2.1 Migrated `config/claude.nix` to use `kit = llmLib.harnessKit.mkKit { ... }; defaultInstructions = kit.mkInstructions "~/.claude/skills";`.
- [x] 2.2 Deleted the inline 149-entry `tierAReadOnlyBash` and `bashAllowEntries`. `settings.permissions.allow = llmLib.allowlist.formatForClaude llmLib.allowlist.tierA;` now.
- [x] 2.3 **Verify**: multiset equality on `permissions.allow` (149 entries pre and post; set-equal).
- [x] 2.4 **Apply**: committed `refactor(claude): consume harness-kit and canonical allowlist`, pushed, `nh darwin switch`.
- [x] 2.5 **Confirm**: wezterm pane spawned `claude --version` cleanly: `2.1.133 (Claude Code)`, exit 0.

## 3. Slice 3 — small-config harnesses

- [x] 3.1 Migrated `config/codex.nix` to kit.
- [x] 3.2 Migrated `config/gemini.nix` to kit (kept the per-harness `geminiSettingsToml` builder).
- [x] 3.3 Migrated `config/cursor.nix` to kit (uses only `kit.mcpServers`; allowlist is via existing `llmLib.mcp.formatPermissionsForCursor`).
- [x] 3.4 Migrated `config/copilot-cli.nix` to kit (`kit.mcpServers` only).
- [x] 3.5 `config/aider.nix` left as-is: no MCP, no skills, nothing to migrate. Kit would add boilerplate for no reuse. Deferred to Phase 2.
- [x] 3.6 **Verify**: byte-identity diff on `cursor/cli-config.json`, `github-copilot/cli/config.json`, `gemini/settings.toml`, `gemini/GEMINI.md` — all four match pre-refactor.
- [x] 3.7 **Apply**: committed `refactor(llm): migrate small-config harnesses to harness-kit`, pushed, `nh darwin switch`.
- [x] 3.8 **Confirm**: headless `--version` smoke test for all five binaries. codex 0.128.0, gemini 0.40.1, cursor-agent 2026.04.08-a41fba1, aider 0.86.1, gh copilot 1.0.40. All launch.

## 4. Slice 4 — medium-config harnesses (kit only)

**Scope shift mid-slice**: amp/crush/goose were originally planned to also adopt the canonical allowlist. Mid-implementation it became clear each has a richer or differently-shaped permission model than the flat Tier A:
- **amp** uses glob-on-cmd matching (`*git commit*`) vs Tier A's exact + trailing-`*` prefix. Different semantics.
- **crush** uses tool-class names (`view`, `openspec`, `ls`, `ripgrep`, `fd`, `ast-grep`) — not bash patterns at all.
- **goose** sources its shell allowlist from `mcp.nix`'s categorized `permissions` (git/github/docker/k8s/nix/utilities/crossplane) — already a canonical-ish source for that axis.

Per the proposal's "where applicable" qualifier, the canonical Tier A allowlist was not applied here. Allowlist migration for these three is deferred to a future revisit (likely as part of `optimize-llm-harnesses` if it becomes a clear win).

- [x] 4.1 Migrated `config/amp.nix` to kit; kept the explicit permissions DSL inline.
- [x] 4.2 Migrated `config/crush.nix` to kit; kept `formatMcpForCrush` local helper and `allowed_tools` list inline.
- [x] 4.3 Migrated `config/goose.nix` to kit; kept the `mcp.nix`-sourced shell allowlist inline.
- [x] 4.4 **Verify**: byte-identity on all four output files (`amp/settings.json`, `crush/crush.json`, `crush/AGENTS.md`, `goose/config.yaml`).
- [x] 4.5 **Apply**: committed `refactor(llm): migrate amp/crush/goose to harness-kit`, pushed, `nh darwin switch`.
- [x] 4.6 **Confirm**: amp 0.0.1775405116, crush v0.65.3, goose 1.28.0 — all launch via `--version`.

## 5. Slice 5 — opencode (kit only)

**Scope shift**: opencode's `permission.bash` uses a per-pattern `allow|ask|deny` trust model — richer than the flat allow-only canonical allowlist. Combining the canonical Tier A with opencode's existing "ask" rules (for `git commit*`, `rm*`, `nh*`, etc.) is a non-trivial shape-merge that risks dropping the "ask" entries. Deferred to a follow-up; kit migration only here.

- [x] 5.1 Migrated `config/opencode.nix` to kit.
- [x] 5.2 Kept the existing inline `permission.bash` allow/ask attrset.
- [x] 5.3 **Verify**: byte-identity on `~/.config/opencode/opencode.json` (matches pre-refactor exactly).
- [x] 5.4 **Apply**: committed `refactor(opencode): consume harness-kit`, pushed, `nh darwin switch`.
- [x] 5.5 **Confirm**: opencode 1.14.35 launches via `--version`.

## 6. Slice 6 — finalize

- [x] 6.1 `./hack/check-agents-md.sh` OK; `instructions.nix` unchanged (kit migration is purely structural).
- [x] 6.2 No-direct-import lint passes: `grep -rE "import \\.\\./(lib/instructions|mcp|skills)\\.nix" modules/home/programs/llm/config/ --include='*.nix' | grep -v 'pi\\.nix'` returns no matches.
- [x] 6.3 `./hack/sync-openspec-skills.sh` and `./hack/sync-openspec-schema.sh` still pass.
- [x] 6.4 `./hack/update-pi.sh` exits zero.
- [x] 6.5 `openspec validate dry-llm-harnesses` exits clean.

## 7. Final validation

- [x] 7.1 `nix flake check` / `nh os build` green throughout.
- [x] 7.2 `nh darwin switch` succeeded after every slice.
- [x] 7.3 All ten rendered config files byte-identical (or multiset-equal for claude's allow array) compared to pre-Slice-1 captures.
- [x] 7.4 Headless `--version` smoke test confirmed every touched harness binary launches. wezterm-driven test for claude confirmed PTY-level launch.
- [x] 7.5 No direct imports of `lib/instructions.nix`, `../mcp.nix`, or `../skills.nix` from `config/` (excluding pi.nix). Direct-import lint clean.
- [x] 7.6 `openspec validate dry-llm-harnesses` clean.
- [x] 7.7 Six scoped conventional commits authored, one per slice plus scaffolding, all pushed to main.

## Deferred to follow-up (`optimize-llm-harnesses`)

- amp/crush/goose/opencode allowlist migration. Each has a permission model richer than the flat canonical Tier A. Shape-merge work belongs in Phase 2 alongside the per-harness max-use audit.
- aider kit migration. Currently no shared imports; revisit if Phase 2 adds MCP or skills surface.
- pi.nix kit migration. Out of scope of this change; pi has its own ecosystem of derivations that don't fit the kit pattern cleanly.
