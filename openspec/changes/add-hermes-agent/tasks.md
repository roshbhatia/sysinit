## 1. Slice 1 — overlay + packages.nix entry

- [x] 1.1 Create `overlays/hermes-agent.nix` following `overlays/cocoindex-code.nix` as the architectural precedent: hand-pinned `fetchurl` from PyPI sdist (`hermes-agent==0.14.0`, sha256 captured inline), `buildPythonApplication` with `pyproject = true`, no optional extras, `wrapProgram` (via `symlinkJoin` + `makeWrapper`) that prepends `final.claude-code`, `final.codex-acp`, `final.opencode`, `final.github-copilot-cli`, `final.gh`, and `final.gemini-cli` onto `PATH`. (Note: `gemini-cli` is the actual derivation name — original task referenced `final.gemini` in error.)
- [x] 1.2 Register the overlay in `overlays/default.nix` adjacent to the `cocoindex-code.nix` import (follows the existing single-import-per-line pattern).
- [x] 1.3 Add `hermes-agent` to the "AI & Editors" cluster in `modules/home/packages.nix` (follows the existing alphabetized grouping in that block).
- [ ] 1.4 Verify: `nix flake check` passes; `nh os build` succeeds; `git diff` reviewed; inspect rendered closure for `hermes-agent-0.14.0` store path; verify wrapped binary script contains the expected `PATH` prefix entries.
- [ ] 1.5 Apply: `nh os switch` on demiurge.
- [ ] 1.6 Confirm: `which hermes` returns a `/nix/store/...-hermes-agent-0.14.0/bin/hermes` path; `hermes --version` reports `0.14.0`; re-running `nh os switch` produces no new generation if no other changes pending.

## 2. Slice 2 — wrapProgram PATH guarantee

- [ ] 2.1 From a fresh `bash -l` (no inherited PATH overrides), run `hermes --help` and confirm the binary starts without error.
- [ ] 2.2 Inspect the wrapper script at `$(which hermes)` (read the script body via `cat`/`bat`) and verify the `PATH=` line prepends the expected subagent derivation paths.
- [ ] 2.3 Verify: with `claude-code` reachable via wrapped PATH only, invoke the `autonomous-ai-agents-claude-code` bundled skill (per upstream docs).
- [ ] 2.4 Confirm: hermes successfully spawns `claude-code` and the subagent returns a response. If failure: capture which binary was missing and either add it to the wrapper's prefix list or document why it's out of scope.

## 3. Slice 3 — runtime env-var matrix and first-provider auth

- [ ] 3.1 Verify: design.md's risk matrix is reviewed by the user; user confirms which provider they intend to authenticate first (default expectation: Anthropic via OAuth through `hermes model`).
- [ ] 3.2 Apply: user runs `hermes setup` on demiurge (interactive — cannot be automated by the change).
- [ ] 3.3 Apply: user runs `hermes model` and selects their first provider; completes OAuth flow if applicable, or sets the relevant env var in `~/.hermes/.env` (or shell rc) if API-key based.
- [ ] 3.4 Confirm: hermes successfully completes a model-response round-trip (any short prompt → response). `~/.hermes/config.yaml` exists; `~/.hermes/auth.json` exists if OAuth was used; nothing in `/etc/` was touched.
- [ ] 3.5 Confirm: a subsequent `nh os switch` does NOT modify any file under `~/.hermes/`.

## 4. Slice 4 — global gitignore entry

- [ ] 4.1 Add `**/.hermes/` to the AI assistants block in `modules/home/programs/git/default.nix` (insert alphabetically between `**/.goose/` and `**/.opencode/`).
- [ ] 4.2 Verify: `nix flake check` passes; `nh os build` succeeds.
- [ ] 4.3 Apply: `nh os switch` on demiurge.
- [ ] 4.4 Confirm: `grep hermes ~/.config/git/ignore` returns the new pattern; the per-project `.gitignore` files in this repo and others remain untouched (the pattern is user-level only).

## 5. Wrap-up

- [ ] 5.1 Verify: every requirement in `specs/hermes-agent-cli/spec.md` is satisfied by the live system on demiurge (manual walkthrough of each scenario).
- [ ] 5.2 Verify: user has rolled hermes out to any additional hosts (e.g. lv426) using the standard `nh os switch` flow, OR has explicitly deferred multi-host rollout.
- [ ] 5.3 Apply: `openspec archive add-hermes-agent` (requires explicit user authorization; per repo policy, the agent does NOT auto-archive).
- [ ] 5.4 Confirm: `openspec list` no longer shows `add-hermes-agent` as active; `openspec/specs/hermes-agent-cli/spec.md` exists with the merged deltas.
