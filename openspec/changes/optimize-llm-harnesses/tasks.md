## 1. Slice 1 — gemini-extensions

- [x] 1.1 Confirmed Gemini CLI extension shape via `gemini extensions --help` + a template scaffold (`gemini extensions new /tmp/probe`). Minimum manifest is `{ name, version }`; richer manifest supports `contextFileName`, `mcpServers`, `description`. Used `contextFileName: "CONTEXT.md"` for in-context prompt content (no startup hooks needed — Gemini auto-loads context files declared in the manifest).
- [x] 1.2 Created `modules/home/programs/llm/config/gemini-extensions/openspec-awareness/{gemini-extension.json,CONTEXT.md}`. Manifest declares name + version + description + contextFileName. CONTEXT.md documents the openspec CLI surface and the rosh-spec-driven workflow.
- [x] 1.3 In `config/gemini.nix`, added a `geminiExtensions` attrset mapping `<name> = ./gemini-extensions/<name>` and a `mkExtensionFiles` helper that reads each extension directory and emits `home.file.".gemini/extensions/<name>/<file>"` entries for every file inside.
- [x] 1.4 **Verify**: `nix build` green; rendered files appear in home-manager output.
- [x] 1.5 **Apply**: committed `feat(gemini): vendor extensions directory and ship openspec-awareness`, pushed, `nh darwin switch`.
- [x] 1.6 **Confirm**: `script -q /dev/null gemini extensions list` reports `✓ openspec-awareness (1.0.0)` with the CONTEXT.md path. `gemini extensions validate ~/.gemini/extensions/openspec-awareness` succeeds.

## 2. Slice 2 — aider-architect-mode

- [ ] 2.1 Inspect aider's documented per-user conventions path (`~/.aider/CONVENTIONS.md` vs `~/.config/aider/CONVENTIONS.md` vs `.aider.conf.yml` `read:` field). Pick the canonical one.
- [ ] 2.2 In `config/aider.nix`, add `architect-model = "anthropic/claude-sonnet-4-5"`, `editor-model = "anthropic/claude-haiku-4-5"`, `architect = true` to `programs.aider-chat.settings`.
- [ ] 2.3 Generate `home.file` entry that renders the same content as `instructions.nix` produces (the AGENTS.md body) at the path identified in 2.1.
- [ ] 2.4 **Verify**: `nix flake check`; `nh os build`; the rendered conventions file content equals the AGENTS.md body (use `./hack/check-agents-md.sh` analog — or just rely on the shared source).
- [ ] 2.5 **Apply**: commit `feat(aider): architect/editor model split and conventions file`, push, `nh darwin switch`.
- [ ] 2.6 **Confirm**: wezterm pane `aider --version` and `aider --help | head -40`; manually verify the help text reflects the architect-mode default.

## 3. Slice 3 — goose-recipes

- [ ] 3.1 Inspect goose's recipe YAML schema (`goose recipe --help`, sample recipes from `~/.config/goose/recipes/` if any exist).
- [ ] 3.2 Identify the source-of-truth Nix strings for openspec workflow content. The Claude skills at `modules/home/programs/llm/skills/openspec-<verb>.nix` (where verb in {propose, apply, explore, archive}) return Nix strings — these are the canonical workflow bodies.
- [ ] 3.3 In `config/goose.nix`, generate `~/.config/goose/recipes/openspec-<verb>.yaml` files. Each YAML has frontmatter (`name`, `description`) plus a `prompt` field whose value is the corresponding skill's body (YAML-escaped).
- [ ] 3.4 **Verify**: `nix flake check`; `nh os build`; each generated YAML parses (try `python3 -c 'import yaml; yaml.safe_load(open("..."))'`).
- [ ] 3.5 **Apply**: commit `feat(goose): vendor recipes for the openspec workflow`, push, `nh darwin switch`.
- [ ] 3.6 **Confirm**: wezterm pane spawning `goose recipe list` (or `goose --help` showing the recipes are registered); inspect at least one rendered file at `~/.config/goose/recipes/openspec-propose.yaml`.

## 4. Slice 4 — cursor-rules-mdc

- [ ] 4.1 Draft three MDC files: `always.mdc` (alwaysApply=true, body=general convention summary from `AGENTS.md`), `nix.mdc` (globs=`["**/*.nix"]`, body=nixfmt/module-layout rules), `markdown.mdc` (globs=`["**/AGENTS.md","**/CLAUDE.md","**/GEMINI.md"]`, body=May-2026 markdown standard rules).
- [ ] 4.2 In `config/cursor.nix`, generate `~/.cursor/rules/<name>.mdc` via `home.file` for each. Add a Nix-side assertion that no rule sets both `alwaysApply: true` AND `globs: [...]` (per the spec).
- [ ] 4.3 Verify the legacy `~/.cursorrules` is NOT removed by this change (audit the current cursor.nix for any cursorrules generation; preserve it).
- [ ] 4.4 **Verify**: `nix flake check`; `nh os build`; each rendered MDC file parses with the expected frontmatter.
- [ ] 4.5 **Apply**: commit `feat(cursor): add MDC rule files alongside legacy .cursorrules`, push, `nh darwin switch`.
- [ ] 4.6 **Confirm**: wezterm pane `cursor-agent --help`; `ls ~/.cursor/rules/` shows the three files; quickly read each file's frontmatter to verify the keys are right.

## 5. Slice 5 — opencode-allowlist-globs

- [ ] 5.1 In `lib/allowlist.nix`, extend `formatForOpencode` to emit glob-compacted keys: `git:*`, `gh:*`, `nix:*`, plus the existing fine-grained entries where compaction would over-broaden (e.g., file ops where `rm*` must stay `ask`).
- [ ] 5.2 Define a helper `inferGlobs tier` that groups patterns by command prefix and emits one `<prefix>:*` per group when all members are `allow`. Patterns that conflict (a tier-A entry and a tier-B entry under the same prefix) emit per-pattern entries.
- [ ] 5.3 In `config/opencode.nix`, replace the inline ~80-entry `permission.bash` allow set with `kit.llmLib.allowlist.formatForOpencode (kit.llmLib.allowlist.tierA ++ kit.llmLib.allowlist.tierB)`. Keep the inline `ask`/`deny` rules (they're policy, not auto-allow).
- [ ] 5.4 Write a small "matcher equivalence" check: list the commands that the OLD opencode allowlist would auto-allow vs the NEW one. The NEW list MUST be a superset of the OLD list at the `allow` axis, AND the OLD `ask` rules MUST still classify their targets as `ask` (since they're inline-preserved).
- [ ] 5.5 **Verify**: `nix flake check`; `nh os build`; the matcher-equivalence check passes; the rendered `~/.config/opencode/opencode.json` `permission.bash` has ≤ 25 entries (target: ~75% reduction).
- [ ] 5.6 **Apply**: commit `feat(opencode): compact bash allowlist via glob patterns`, push, `nh darwin switch`.
- [ ] 5.7 **Confirm**: wezterm pane `opencode --version`; inspect `~/.config/opencode/opencode.json` `permission.bash` to confirm the slim shape.

## 6. Slice 6 — codex-reasoning-effort

- [ ] 6.1 Inspect home-manager's `programs.codex.settings` shape to find the right path for profiles (`profiles.<name>.reasoning_effort` or a raw TOML block). If unclear, render to `~/.codex/config.toml` via `xdg.configFile` directly.
- [ ] 6.2 In `config/codex.nix`, declare two profiles: `default` (`reasoning_effort = "low"`) and `spec` (`reasoning_effort = "high"`, `model_reasoning_summary = "detailed"`).
- [ ] 6.3 **Verify**: `nix flake check`; `nh os build`; rendered `~/.codex/config.toml` contains both profile sections.
- [ ] 6.4 **Apply**: commit `feat(codex): add default and spec profiles with reasoning_effort`, push, `nh darwin switch`.
- [ ] 6.5 **Confirm**: wezterm pane `codex --version` and `codex --profile spec --help` (or whatever the codex CLI accepts for profile selection); confirm the profile is recognized without error.

## 7. Slice 7 — finalize

- [ ] 7.1 `./hack/check-agents-md.sh` clean; `./hack/sync-openspec-skills.sh` clean; `./hack/sync-openspec-schema.sh` clean; `./hack/update-pi.sh` clean.
- [ ] 7.2 No-direct-import lint still passes (from `dry-llm-harnesses`): `grep -rE "import \\.\\./(lib/instructions|mcp|skills)\\.nix" modules/home/programs/llm/config/ --include='*.nix' | grep -v 'pi\\.nix'` empty.
- [ ] 7.3 `openspec validate optimize-llm-harnesses` clean.
- [ ] 7.4 wezterm smoke test for each touched harness one more time after the final switch: gemini, aider, goose, cursor-agent, opencode, codex.

## 8. Final validation

- [ ] 8.1 `nix flake check` and `nh os build` green throughout.
- [ ] 8.2 Six scoped conventional commits (one per slice), each pushed to main.
- [ ] 8.3 `openspec validate optimize-llm-harnesses` exits clean.
- [ ] 8.4 Each of the six new spec files in `specs/<capability>/spec.md` has all requirements satisfied per the spec's scenarios.
- [ ] 8.5 Archive: `openspec archive optimize-llm-harnesses --yes`.
