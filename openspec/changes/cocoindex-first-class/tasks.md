## 1. Slice 1 — gitignore + allowlist (zero-runtime additive)

- [ ] 1.1 Add `**/.cocoindex_code/` to the AI-assistants block of `home.programs.git-config.ignores` in `modules/home/programs/git/default.nix` (follows the existing pattern alongside `**/.claude/`, `**/.agents/`).
- [ ] 1.2 Add `ccc search`, `ccc search *`, and `ccc status` to `tierA` in `modules/home/programs/llm/lib/allowlist.nix` (follows the existing tier-A grouping style; place near other read-only tool clusters).
- [ ] 1.3 Verify: `nix flake check` passes; `nh os build` succeeds; `git diff` reviewed.
- [ ] 1.4 Apply: `nh os switch` on hyperion (work mac).
- [ ] 1.5 Confirm: `cat ~/.config/git/ignore | grep cocoindex_code` returns the new pattern; spot-check a Claude session's allowlist includes `Bash(ccc search *)`.

## 2. Slice 2 — pipx activation install

- [ ] 2.1 Add `pkgs.pipx` to `home.packages` in `modules/home/programs/llm/default.nix` so the activation step's prerequisite is satisfied.
- [ ] 2.2 Create activation entry `home.activation.installCocoindexCode` in the same LLM module (follows the `home.activation.updatePiSettings` pattern in `modules/home/programs/llm/config/pi.nix`): idempotent `pipx install 'cocoindex-code[full]' --include-deps` guarded by a `pipx list` check; fails loudly if `pipx` is missing.
- [ ] 2.3 Verify: `nix flake check` passes; `nh os build` succeeds; review the rendered activation script under the build output for the expected idempotency guard.
- [ ] 2.4 Apply: `nh os switch` on hyperion.
- [ ] 2.5 Confirm: in a fresh shell, `which ccc` resolves and `ccc --version` returns a value; re-running `nh os switch` does not re-trigger the install (activation log shows the no-op path).
- [ ] 2.6 Hold rollout to other hosts until user explicitly authorizes (large download).

## 3. Slice 3 — cocoindex MCP server entry

- [ ] 3.1 Add a `cocoindex` server entry to `sysinit.llm.mcp.additionalServers` in `modules/home/programs/llm/config/mcp-servers.nix` (follows the existing `ast-grep` and `playwright` entries): `command = "ccc"`, `args = [ "mcp" ]`, `description` naming it as the semantic code search server.
- [ ] 3.2 Verify: `nix flake check` passes; `nh os build` succeeds; inspect a couple of rendered harness configs in the build output to confirm `cocoindex` appears.
- [ ] 3.3 Apply: `nh os switch` on hyperion.
- [ ] 3.4 Confirm: open at least three harnesses (claude, codex, one other — gemini or goose) and verify each lists `cocoindex:search` (or harness-equivalent naming) in its tool inventory.

## 4. Slice 4 — active-routing skill rewrite

- [ ] 4.1 Rewrite `modules/home/programs/llm/skills/cocoindex-query.nix` to active routing: explicitly state cocoindex MCP search is preferred for intent/semantic queries; `rg`/`grep` is the fallback for literal-string matches; instruct passing `refresh_index=True` on first call in a new project; instruct graceful fallback to `rg` on any cocoindex error. Drop the passive "may not be running" language.
- [ ] 4.2 Verify: `nix flake check` passes; `nh os build` succeeds; render the resulting `SKILL.md` from the build output and confirm the language matches the spec scenarios in `specs/agent-skill-library/spec.md`.
- [ ] 4.3 Apply: `nh os switch` on hyperion.
- [ ] 4.4 Confirm: run a known semantic query in one harness (e.g., "where do we format MCP servers for goose?") and verify cocoindex is called before any `rg` fallback in the tool-use trace.

## 5. Slice 5 — work-host Laurel plugin install (hyperion, farcaster)

- [ ] 5.1 Add `pkgs.jq` to `home.packages` in the LLM module if not already present (the activation script parses Claude plugin state JSON).
- [ ] 5.2 Add a host-gated `home.activation.installLaurelPlugin` entry under the existing claude-code config module (gated by `lib.mkIf (config.home.username == "roshan")`). The script: 1) verifies `claude` is on PATH; 2) checks `~/.claude/plugins/known_marketplaces.json` for a `Laurel` entry and runs `claude plugin marketplace add pinginc/ai-tooling` only if absent; 3) checks `~/.claude/plugins/installed_plugins.json` for a `Laurel@Laurel` entry and runs `claude plugin install Laurel@Laurel` only if absent; 4) prints a one-line notice that auto-update must be enabled manually in the TUI.
- [ ] 5.3 Verify: `nix flake check` passes; `nh os build` succeeds; review the rendered activation script for the host-gated guard and the idempotency checks.
- [ ] 5.4 Apply: `nh os switch` (or `nh darwin switch`) on hyperion.
- [ ] 5.5 Confirm: `claude plugin list` shows `Laurel@Laurel` installed; `~/.claude/plugins/known_marketplaces.json` has the `Laurel` entry; `~/.claude/plugins/installed_plugins.json` has the plugin entry.
- [ ] 5.6 One-time manual step: in the Claude TUI run `/plugin`, navigate to Marketplaces → Laurel, select "Enable auto-update".
- [ ] 5.7 Verify before rolling to farcaster: re-running `nh os switch` on hyperion is a no-op (no `claude plugin marketplace add` or `claude plugin install` re-invocations in the activation log).
- [ ] 5.8 Apply: `nh os switch` on farcaster after explicit user authorization.
- [ ] 5.9 Confirm on farcaster: same checks as 5.5; user enables auto-update in the TUI on farcaster as well.
- [ ] 5.10 Verify personal-host behavior: spot-check that `nh os switch` on a personal host (lv426 or arrakis) does NOT register the marketplace or install the plugin (the `lib.mkIf` guard skips the activation entry).

## 6. Slice 6 — multi-host cocoindex rollout

- [ ] 6.1 Verify (per host): user reviews the consolidated diff covering Slices 1–4 and confirms readiness for each target host.
- [ ] 6.2 Apply: `nh os switch` on each remaining host one at a time (lv426, then arrakis if applicable, then any others).
- [ ] 6.3 Confirm (per host): `ccc --version` returns; one semantic query in one harness on that host returns chunks (or cleanly falls back to `rg` for a literal probe).

## 7. Wrap-up

- [ ] 7.1 Verify: every scenario in each `specs/*/spec.md` of this change is satisfied by the live system (manual walkthrough).
- [ ] 7.2 Apply: `openspec archive cocoindex-first-class` (only after user explicit authorization).
- [ ] 7.3 Confirm: `openspec list` no longer shows `cocoindex-first-class` as active; the deltas are merged into the project's authoritative specs.
