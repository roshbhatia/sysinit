## Why

The pi coding agent integration in `modules/home/programs/llm/config/pi.nix` has drifted significantly. The upstream extensions source repo was renamed from `badlogic/pi-mono` to `earendil-works/pi` and our pin sits 1,012 commits behind main. Eight of our sixteen vendored npm packages have newer versions on the registry, with `pi-subagents` jumping 13 minor versions (0.11.2 → 0.24.2) and `pi-ask-user` jumping 6 (0.5.1 → 0.11.0). The pi ecosystem has also exploded since the last refresh — pi.dev now hosts 80+ third-party extensions covering permission enforcement, multi-agent orchestration, session memory, plan annotation, and provider-specific tooling that aligns naturally with our spec-driven workflow. Refreshing now closes the drift gap before it compounds and brings pi into the same first-class status as Claude Code and Codex in this dotfiles repo.

## What Changes

- Rename the pi-mono source from `badlogic/pi-mono` to `earendil-works/pi`; bump the pin to a recent commit on main.
- Bump every stale npm pin to its latest version (9 packages with version drift, 7 already current).
- Bump the pi CLI (`piAcp` derivation) from 0.0.24 to 0.0.26.
- Delete the orphan `locks/pi-pretty.lock.json` — `pi-pretty` does not exist on npm.
- Refresh the theme schema URL reference from `badlogic/pi-mono` to `earendil-works/pi`.
- Add 10 new pi packages: `taskplane`, `@plannotator/pi-extension`, `pi-btw`, `@samfp/pi-memory`, `@gotgenes/pi-permission-system`, `@benvargas/pi-claude-code-use`, `@benvargas/pi-openai-fast`, `@benvargas/pi-openai-verbosity`, `@firstpick/pi-extension-reverse-last`, `@juicesharp/rpiv-advisor`.
- Remove `confirm-destructive` from the vendored upstream extensions list once `@gotgenes/pi-permission-system` is loaded — the latter is finer-grained and would conflict otherwise.
- Add a custom read-only `openspec-status.ts` extension to `.pi/agent/extensions/` that shows the active openspec change name and task progress in pi's status line.
- Add `hack/update-pi.sh` — analogous to `hack/update-openspec.sh` — that queries npm for each pinned package and recomputes hashes via the fake-hash technique, so future drift surfaces in one command.

### Non-goals

- Switching pi from local-path package loading to npm-direct loading (we keep the Nix-vendored model).
- Adopting `pi-markdown-preview` (puppeteer-core dep fights Nix sandbox) or `pi-lens` (multiple deps, marginal benefit over our editor toolchain) — both candidates were considered and dropped.
- Adopting `context-mode`, `pi-simplify`, `@ollama/pi-web-search`, `@ff-labs/pi-fff`, or `@juicesharp/rpiv-pi` — each duplicates existing capability or has prohibitive deps; documented in the audit.
- Writing a gating version of the openspec-status extension (refusing writes when no change is in apply phase). Read-only first; revisit gating after a usage period.
- Building a Taskfile target for `task pi:update` — no Taskfile in this repo yet. The script is callable directly via `./hack/update-pi.sh`.

## Capabilities

### New Capabilities

- `pi-package-vendoring`: How pi extensions and CLIs are pinned, fetched, built, and exposed to the pi runtime via `~/.pi/agent/settings.json` `packages` paths. Includes the required-vs-optional package list and the drift-detection workflow.
- `pi-extension-config`: How per-extension configuration files at `~/.pi/agent/extensions/<name>/config.json` are generated from Nix, how conflicting extensions are resolved, and the load-order constraints between permission enforcement, provider routing, orchestration, and UI extensions.
- `pi-openspec-bridge`: How the read-only `openspec-status.ts` extension reads active openspec change state and surfaces it in pi's status line, and the contract it relies on (the `openspec` CLI being on PATH, `openspec list --json` schema).

### Modified Capabilities

None. No prior `openspec/specs/pi-*` content exists.

## Impact

- **Code touched**: `modules/home/programs/llm/config/pi.nix` (heavy), `modules/home/programs/llm/config/locks/` (delete one, add several), new extension TS file under `modules/home/programs/llm/config/extensions/`, new `hack/update-pi.sh`, possibly `AGENTS.md` if commands section gets a `task pi:update` mention deferred to a follow-up.
- **Removed**: `modules/home/programs/llm/config/locks/pi-pretty.lock.json`. `confirm-destructive` removed from the vendored upstream extension names.
- **External dependencies**: 10 new npm packages from the registry, all version + hash pinned. `tree-sitter-bash`/`web-tree-sitter` come in via `@gotgenes/pi-permission-system` (WASM, no native compile needed). `puppeteer-core` and native LSP modules deliberately excluded by package choice.
- **Impactful actions** (each MUST be wrapped in verify/apply/confirm in tasks.md):
  - `nh darwin switch .` — applies all package changes and the new extension to the live system. Single biggest blast radius.
  - Removing `confirm-destructive` from the upstream-extensions list — changes which permission gate is active.
  - First load of `@gotgenes/pi-permission-system` — may prompt for policy decisions; user should review on first run.
  - Hash-recomputation runs (`update-pi.sh` first execution) — Nix builds fail loudly on hash drift, so safe by construction.
- **Risk surface**: The peer-dependency split (`@mariozechner/pi-coding-agent` vs `@earendil-works/pi-coding-agent`) is the highest-risk axis. Five of the new packages still target the old peer scope. Pi loads via local paths so peer deps are advisory at runtime, but if any package's source imports from the old scope it will break.
- **Gating signal**: Default for this repo — `nix flake check` → `nh os build` (no system change) → user spot-check → `nh os switch` → smoke test `pi --version` and `pi --list-extensions` (or equivalent). Each phase below corresponds to a coherent vertical slice; the schema's progressive-rollout rule means new packages land in batches rather than as a single drop.
