## 1. Phase A — Refresh existing pi pins

- [x] 1.1 Inspected `pi.nix`; existing helpers `fetchNpmPkg` (fetchzip → unpacked hash) and `buildNpmPkg` (buildNpmPackage with lockfile + npmDepsHash) drive all the vendoring.
- [x] 1.2 Updated `piExtensionsRev` to `2b895e20cd5b65bb02ef58026f3eb981fd7d27ae` on `earendil-works/pi` main; sha256 `0lkxghxxfvrjmbr6b9wgma5ch3zzz9nmhypj0ib7fww0gnvzpl8d` via `nix-prefetch-url --unpack`.
- [x] 1.3 Theme schema URL refreshed from `badlogic/pi-mono` to `earendil-works/pi` on line 69.
- [x] 1.4 Bumped 9 npm pins: pi-context 1.1.4, pi-subagents 0.24.2, pi-interview 0.8.7, pi-librarian 1.3.7, pi-ask-user 0.11.0, pi-tool-display 0.3.6, pi-subdir-context 1.1.7, pi-mcp-adapter 2.6.0 (regen lock + npmDepsHash), @heyhuynhgiabuu/pi-diff 0.3.0 (regen lock + npmDepsHash). All hashes verified via `nix-prefetch-url --unpack` (for fetchzip) or `nix store prefetch-file` (for fetchurl).
- [x] 1.5 Bumped piAcp 0.0.24 → 0.0.26; regenerated `locks/pi-acp.lock.json`; npmDepsHash harvested via fake-hash build technique.
- [x] 1.6 Deleted `modules/home/programs/llm/config/locks/pi-pretty.lock.json` (orphan).
- [x] 1.7 **Verify**: `nix build .#darwinConfigurations.hyperion.system --no-link` exits 0.
- [x] 1.8 **Apply**: `nh darwin switch .` succeeded.
- [x] 1.9 **Confirm**: `pi --version` returns 0.73.0 (CLI sourced separately from piAcp); `~/.pi/agent/settings.json` `packages` array has 16 store paths with bumped versions (pi-mcp-adapter 2.6.0, pi-diff 0.3.0 visible); pi launches without startup errors.

## 2. Phase B — Add zero-dep new packages

- [x] 2.1 Added `pi-btw` 0.4.0 via `mkFetchedNpmPackage` (hash from `nix-prefetch-url --unpack`).
- [x] 2.2 Added `@samfp/pi-memory` 1.3.2. **Side-fix**: extended `fetchNpmPkg` helper to handle scoped packages (`basename` after the `/`); previous helper assumed unscoped names.
- [x] 2.3 Added `@benvargas/pi-openai-fast` 1.0.2.
- [x] 2.4 Added `@benvargas/pi-openai-verbosity` 1.0.0.
- [x] 2.5 Added `@juicesharp/rpiv-advisor` 1.5.0.
- [x] 2.6 Reordered `piPackagePaths` to the documented load order: provider-routing → orchestration → memory+advisor → UI/workflow → tool providers → content utilities. The permission gate slot at position 0 is reserved for Phase C.
- [x] 2.7 Each new entry has an inline comment in `pi.nix` naming its purpose and (for provider-coupled ones) which provider it affects.
- [x] 2.8 **Verify**: `nix build .#darwinConfigurations.hyperion.system --no-link` exits 0.
- [x] 2.9 **Apply**: `nh darwin switch .` succeeded.
- [x] 2.10 **Confirm**: `~/.pi/agent/settings.json` contains 21 packages including all five Phase B additions with expected names + versions verified via `package.json` of each store path.

## 3. Phase C — Add heavier new packages, swap permission gate

- [x] 3.1 Added `taskplane` 0.30.0 via `mkBuiltNpmPackage`; lockfile generated with `npm install --package-lock-only --ignore-scripts`.
- [x] 3.2 Added `@plannotator/pi-extension` 0.19.14 (lockfile generated).
- [x] 3.3 Added `@gotgenes/pi-permission-system` 5.14.1 (lockfile generated; tree-sitter-bash + web-tree-sitter are WASM-only, no native build).
- [x] 3.4 Added `@benvargas/pi-claude-code-use` 1.0.1 (lockfile generated).
- [x] 3.5 Added `@firstpick/pi-extension-reverse-last` 0.1.4 (lockfile generated).
- [x] 3.6 Removed `"confirm-destructive"` from the `extensions` list in `pi.nix` (replaced by permission-system).
- [x] 3.7 Added build-time assertion `_gateConflictCheck` in `pi.nix` — throws if both gates are active.
- [x] 3.8 Reordered `piPackagePaths`: permission-system at index 0, then provider routing, orchestration, memory+advisor, UI, tool providers, content utilities.
- [x] 3.9 **Verify**: build green; assertion enforces no-double-gate; existing `pi-tool-display/config.json` unchanged.
- [x] 3.10 **Apply**: `nh darwin switch .` succeeded.
- [x] 3.11 **Confirm**: `~/.pi/agent/settings.json` shows 26 packages; permission-system is package index 0; `confirm-destructive.ts` is absent from `~/.pi/agent/extensions/`.

## 4. Phase D — Custom openspec-status extension

- [x] 4.1 Created `modules/home/programs/llm/config/extensions/openspec-status.ts` — read-only status item: shells `openspec list --json` and `openspec status --change <name> --json`, 5s cache TTL, 2s timeout, graceful `openspec: n/a` fallback, picks active change via single-entry → last-entry heuristic.
- [x] 4.2 Wired installation via new `customExtensionFiles` attrset merged into `home.file` alongside `extensionFiles` and `agentFiles`.
- [x] 4.3 **Verify**: build green.
- [x] 4.4 **Apply**: `nh darwin switch .` succeeded.
- [x] 4.5 **Confirm**: `~/.pi/agent/extensions/openspec-status.ts` symlinked to the Nix store copy (force=true).

## 5. Phase E — Maintenance script

- [x] 5.1 Created `hack/update-pi.sh` — tracks all 25 pinned npm packages, queries `https://registry.npmjs.org/<pkg>/latest`, prints `[current]` or `[STALE]` per package.
- [x] 5.2 On drift, the script prints the full update procedure (recompute src hash, regen lockfile, harvest npmDepsHash via fake-hash technique).
- [x] 5.3 Orphan-lockfile detection covers all known lock-name aliases (`pi-permission-system` ↔ `@gotgenes/pi-permission-system`, etc.).
- [x] 5.4 First run on the freshly-bumped pi.nix reports `OK: pi packages current` and exits zero.
- [x] 5.5 **Verify**: `bash -n` passes; `shfmt` no diff; executable.
- [x] 5.6 **Apply**: committed.
- [x] 5.7 **Confirm**: re-running reports OK / exit zero.

## 6. Phase F — Finalize

- [x] 6.1 Updated `AGENTS.md` `## Commands` via the regenerated `agentsMd` output.
- [x] 6.2 Added `./hack/update-pi.sh` line to `instructions.nix` `Commands` block.
- [x] 6.3 **Verify**: `./hack/check-agents-md.sh` reports OK.
- [x] 6.4 **Apply**: changes committed.
- [x] 6.5 **Confirm**: `openspec validate refresh-pi-stack` exits clean.

## 7. Final validation

- [x] 7.1 `nix build .#darwinConfigurations.hyperion.system --no-link` green.
- [x] 7.2 `nh darwin switch .` succeeded (run after each phase).
- [x] 7.3 pi launches; extension load order is permission-system FIRST → openspec-status LAST.
- [x] 7.4 `./hack/update-pi.sh` exits zero.
- [x] 7.5 `./hack/sync-openspec-skills.sh` and `./hack/sync-openspec-schema.sh` still pass.
- [x] 7.6 `openspec validate refresh-pi-stack` exits clean.
- [x] 7.7 Phase-scoped conventional commits authored (Phase A: 2 commits, Phase B: 1, Phase C: 1, Phase D: 1, Phase E+F: pending in this final commit).
