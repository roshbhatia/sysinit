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

- [ ] 2.1 Add `pi-btw` 0.4.0 to the `piPackages` attrset using `mkFetchedNpmPackage` (no runtime deps).
- [ ] 2.2 Add `@samfp/pi-memory` 1.3.2 the same way (handle scoped package URL).
- [ ] 2.3 Add `@benvargas/pi-openai-fast` 1.0.2 the same way.
- [ ] 2.4 Add `@benvargas/pi-openai-verbosity` 1.0.0 the same way.
- [ ] 2.5 Add `@juicesharp/rpiv-advisor` 1.5.0 the same way.
- [ ] 2.6 Insert the five entries into `piPackagePaths` array in the documented load-order positions (provider-routing for the @benvargas pair after permission-system slot; memory + advisor in their own group; pi-btw in UI/workflow group).
- [ ] 2.7 Annotate each new entry with an inline comment naming its purpose and (for provider-coupled ones) which provider it affects.
- [ ] 2.8 **Verify**: `nix flake check` passes; `nh os build .` succeeds; `git diff` reviewed.
- [ ] 2.9 **Apply**: `nh darwin switch .`.
- [ ] 2.10 **Confirm**: `~/.pi/agent/settings.json` `packages` array contains store paths for all five new packages in the correct array positions; launch pi and confirm `/btw` slash command is recognized.

## 3. Phase C — Add heavier new packages, swap permission gate

- [ ] 3.1 Add `taskplane` 0.30.0 using `buildNpmPkg`; generate `locks/taskplane.lock.json` (run `npm install --package-lock-only` against the fetched tarball, capture the lock).
- [ ] 3.2 Add `@plannotator/pi-extension` 0.19.14 using `buildNpmPkg`; generate its lock file.
- [ ] 3.3 Add `@gotgenes/pi-permission-system` 5.14.1 using `buildNpmPkg`; generate its lock file (carries `tree-sitter-bash` + `web-tree-sitter` WASM, no native build).
- [ ] 3.4 Add `@benvargas/pi-claude-code-use` 1.0.1 using `buildNpmPkg`; generate its lock file (3 pure-JS deps).
- [ ] 3.5 Add `@firstpick/pi-extension-reverse-last` 0.1.4 using `buildNpmPkg`; generate its lock file.
- [ ] 3.6 Remove `"confirm-destructive"` from the `extensions` list in `pi.nix` (Phase D9 in design D2).
- [ ] 3.7 Add a Nix build-time assertion: if `"@gotgenes/pi-permission-system"` appears in the package names and `"confirm-destructive"` appears in `extensions`, throw with a message naming both.
- [ ] 3.8 Insert the five new packages into `piPackagePaths` at the correct load-order positions: `@gotgenes/pi-permission-system` FIRST (before all tool-providers), then `@benvargas/pi-claude-code-use` in provider-routing, `taskplane` in orchestration, `@plannotator/pi-extension` and `@firstpick/pi-extension-reverse-last` in UI/workflow.
- [ ] 3.9 **Verify**: `nix flake check` passes (asserts the no-double-gate rule); `nh os build .` succeeds; `git diff` reviewed; existing `pi-tool-display/config.json` still pins `bash: true` (which permission-system will now wrap).
- [ ] 3.10 **Apply**: `nh darwin switch .`.
- [ ] 3.11 **Confirm**: `~/.claude/skills` unchanged (Claude allowlist still intact); `~/.pi/agent/settings.json` shows new packages and `confirm-destructive.ts` is absent from `~/.pi/agent/extensions/`; launch pi and observe permission-system's first-run prompt; tune `~/.pi/agent/extensions/@gotgenes/pi-permission-system/config.json` if it blocks expected workflows.

## 4. Phase D — Custom openspec-status extension

- [ ] 4.1 Create `modules/home/programs/llm/config/extensions/openspec-status.ts` implementing the read-only behavior per `specs/pi-openspec-bridge/spec.md`: shell-out to `openspec list --json` (5s cache TTL, 2s timeout), single status-line item, graceful degradation to `openspec: n/a` on failure (pattern follows the existing TS files vendored from upstream).
- [ ] 4.2 Wire its installation in `pi.nix` via a `home.file.".pi/agent/extensions/openspec-status.ts"` entry that sources the file (follows the pattern of the `extensionFiles` lib.listToAttrs block).
- [ ] 4.3 **Verify**: `nix flake check` passes; `nh os build .` succeeds; the resulting file appears in the rendered home-manager output; the TS file passes a quick `tsc --noEmit` (or `bun --check`) sanity pass.
- [ ] 4.4 **Apply**: `nh darwin switch .`.
- [ ] 4.5 **Confirm**: `~/.pi/agent/extensions/openspec-status.ts` exists byte-identical to the Nix source; launch pi and verify the status line shows `openspec: <change>` (with refresh-pi-stack active) or `openspec: idle` (after archive); `openspec list --json` keeps responding under 2s.

## 5. Phase E — Maintenance script

- [ ] 5.1 Create `hack/update-pi.sh` (`set -euo pipefail`, shfmt-formatted) — follows the pattern of `hack/update-openspec.sh`. Iterates over a hard-coded list of pi packages, queries `https://registry.npmjs.org/<pkg>/latest`, compares against the version string in `pi.nix`, and prints a per-package report.
- [ ] 5.2 For each stale package, the script SHALL print the `nix-prefetch-url` command needed to recompute the SRI hash; for `buildNpmPackage` entries it SHALL additionally print instructions for regenerating the lock file.
- [ ] 5.3 Detect orphan lock files in `locks/`: any `<name>.lock.json` whose name doesn't match a package in `pi.nix` is reported and the script exits non-zero.
- [ ] 5.4 Run the script on the freshly-bumped pi.nix — it MUST exit zero (no drift) at this point in the change.
- [ ] 5.5 **Verify**: `bash -n hack/update-pi.sh` passes; `shfmt -d -i 2 -ci -sr -s hack/update-pi.sh` reports no changes; script is `chmod +x`.
- [ ] 5.6 **Apply**: `git add hack/update-pi.sh`; commit alongside the maintenance script.
- [ ] 5.7 **Confirm**: running `./hack/update-pi.sh` reports `OK: pi packages current` and exits zero.

## 6. Phase F — Finalize

- [ ] 6.1 Update `AGENTS.md` `## Commands` section to mention `./hack/update-pi.sh` in the maintenance group (regenerate via `cp $(nix build .#packages.aarch64-darwin.agentsMd --no-link --print-out-paths) AGENTS.md` after editing `instructions.nix`).
- [ ] 6.2 Add a line to `instructions.nix` `Commands` section: `./hack/update-pi.sh        # report pi package drift`.
- [ ] 6.3 **Verify**: `./hack/check-agents-md.sh` reports OK; rendered AGENTS.md contains the new command line.
- [ ] 6.4 **Apply**: commit AGENTS.md + instructions.nix update.
- [ ] 6.5 **Confirm**: `openspec validate refresh-pi-stack` exits clean; the change is ready to archive.

## 7. Final validation

- [ ] 7.1 `nix flake check` green.
- [ ] 7.2 `nh os build .#hyperion` succeeds.
- [ ] 7.3 Launch pi: status line shows `openspec: <name>` or `openspec: idle`; no extension load errors in the startup log.
- [ ] 7.4 `./hack/update-pi.sh` exits zero (current).
- [ ] 7.5 `./hack/sync-openspec-skills.sh` and `./hack/sync-openspec-schema.sh` still pass.
- [ ] 7.6 `openspec validate refresh-pi-stack` exits clean.
- [ ] 7.7 Commits authored in scoped batches per phase (Phase A → A commits, Phase B → B commits, etc.) under conventional-commit titles, no bodies.
