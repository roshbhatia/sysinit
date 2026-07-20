# Tasks

## 1. opencode plugins (DONE)

- [x] **Apply**: Add `opencode-openai-codex-auth@latest`, `opencode-pty`,
      `opencode-vibeguard`, `@franlol/opencode-md-table-formatter@latest` to the
      `plugin` array in `config/opencode.nix`, each with a one-line rationale
      comment. Skip `jenslys/opencode-gemini-auth` (duplicate of existing
      `opencode-gemini-auth@latest`) and `JRedeker/opencode-shell-strategy`
      (its `main` is an instructions doc, not a plugin; conflicts with pty).
- [x] **Verify**: `nix-instantiate --parse config/opencode.nix` → PARSE OK.
- [x] **Confirm**: `nh darwin build` succeeds and the rendered opencode config
      lists all 8 plugins.

## 2. Claude destructive-command guard

- [x] **Apply**: Add a `claude-bash-guard` `pkgs.writeShellApplication` in
      `config/claude.nix` (`runtimeInputs = [ pkgs.jq ]`) that reads stdin,
      extracts `.tool_input.command`, matches the deny patterns from design.md,
      and prints the `permissionDecision: "deny"` JSON on a hit (silent exit 0
      otherwise).
- [x] **Apply**: Wire it into `settings.hooks.PreToolUse` with
      `matcher = "Bash"` (not `async`), mirroring the `notify.exe` wiring.
- [x] **Verify**: Unit-exercise the script offline — pipe sample JSON for
      `git push --force`, `--no-verify`, `git reset --hard`, `git clean -fd`,
      `git branch -D x` (expect deny) and `git push origin main`, `git status`,
      `nh darwin build` (expect silent pass). All 18 cases pass.
- [x] **Verify**: `nix flake check` passes.
- [ ] **Confirm**: After `nh darwin switch`, in a Claude Code session a
      `git push --force` attempt is denied with the prohibition reason, and a
      plain `git push` to main is still permitted.

## 3. Skills-root unification

- [x] **Apply**: Change the `mkInstructions` skills-root arg in
      `config/opencode.nix` and the Crush config from
      `~/.config/opencode/skills` / `~/.config/crush/skills` to
      `~/.claude/skills`.
- [x] **Verify**: `nix flake check` passes; rendered opencode/Crush
      instructions reference `~/.claude/skills`.
- [ ] **Confirm**: After switch, a known skill (e.g. `search-code-routing`)
      resolves from opencode and Crush.

## 4. Two-tier model config

- [x] **Apply**: Read the current default/large model for opencode and Crush;
      set opencode `small_model` and Crush `models.small` to the matching
      Haiku-class cheap tier.
- [x] **Verify**: `nix flake check` passes; rendered configs carry the small
      model.
- [ ] **Confirm**: After switch, opencode/Crush use the cheap model for
      titles/summaries and the strong model for primary work.

## 5. claude.nix documented-key cleanup

- [x] **Apply**: Remove `autoCompactWindow`. Either drop `autoCompactEnabled`
      (default `true`) or set it explicitly. Remove `autoDreamEnabled`, or keep
      it with an explicit "undocumented — verify via /config" comment alongside
      the existing `tui` note.
- [x] **Verify**: `nix flake check` passes; `/config` after switch shows no
      rejected/unknown keys.
- [ ] **Confirm**: Auto-compact still behaves (fires near the context limit);
      no regression from dropping the custom window.

## 6. Agent Teams enablement

- [x] **Apply**: Add `settings.env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1"`
      in `config/claude.nix` (coexisting with enterprise managed-settings env;
      this key is user-scoped and not set by the company layer).
- [x] **Verify**: `nix flake check` passes; rendered settings.json carries the
      env key.
- [ ] **Confirm**: After switch, Agent Teams is available in a session
      (lead/teammate flow selectable); Dynamic Workflows need no config and
      remain usage-opt-in (documented in design.md, no settings change).

## 7. Gemini → Antigravity (`agy`) migration

- [x] **Verify (gate)**: Build the package and inspect the REAL binary before
      writing any config — `nix build nixpkgs#antigravity-cli` (or
      `nix run nixpkgs#antigravity-cli -- --help`). Confirm against the binary:
      (a) the settings path/format (`~/.gemini/antigravity-cli/settings.json`?),
      (b) the MCP config path and JSON schema/key names
      (`~/.gemini/config/mcp_config.json`? `{command,args,env}` vs other),
      (c) whether `AGENTS.md` is read natively without a per-tool context file,
      (d) the plugin manifest format vs the existing `gemini-extension.json`,
      (e) auth flow (keyring + Google Sign-In). Record findings in design.md.
      **If the surface diverges materially from Decision 6's table, re-scope
      before proceeding.**
- [x] **Apply**: In `config/gemini.nix`, swap `pkgs.gemini-cli` →
      `pkgs.antigravity-cli`. Move MCP declarations off `settings.toml`
      (`llmLib.mcp.formatForGemini`, TOML) onto agy's JSON MCP config using the
      closest existing JSON formatter in `lib/mcp.nix` (confirmed key names from
      the gate step); add a JSON formatter only if none matches. Reused
      `formatForClaude` wrapped as `{ mcpServers = … }` →
      `~/.gemini/config/mcp_config.json`; added `"antigravity-cli"` to the
      `allowUnfreePredicate` in `lib/builders/pkgs.nix` (gate-step finding).
- [x] **Apply**: Drop the per-tool `GEMINI.md` write if the gate step confirmed
      agy reads the shared `AGENTS.md` natively; otherwise keep a legacy
      `GEMINI.md` write for parity. Re-home `gemini-extensions/openspec-awareness`
      as an agy plugin, vendoring its files declaratively (no curl-installer),
      translating the manifest if agy's plugin format differs. GEMINI.md dropped;
      global rules write to `~/.agents/AGENTS.md`. Plugin re-homed under
      `~/.gemini/config/plugins/openspec-awareness/` (`plugin.json` + `CONTEXT.md`)
      with a declarative `import_manifest.json` registry entry.
- [x] **Verify**: `nix flake check` passes; rendered agy config carries the MCP
      servers and (if kept) context file; the openspec plugin files are present
      at agy's plugin path. Confirmed: `mcp_config.json` carries ast-grep +
      playwright; plugin dir holds `plugin.json` + `CONTEXT.md`;
      `import_manifest.json` registers the plugin; `nh darwin build` diff shows
      the old gemini settings.toml/GEMINI.md/extension.json removed.
- [ ] **Confirm**: After switch, `agy` launches, lists the MCP servers, picks up
      repo `AGENTS.md`, and the openspec plugin loads; no source is
      auto-updated.

## 8. Final validation

- [x] **Verify**: `nix fmt` clean; `nix flake check` green; `nh darwin build`
      succeeds for the current host. (build: 18 derivations, exit 0;
      one pre-existing Codex 0.134 `profiles` deprecation trace, out of scope.)
- [ ] **Confirm**: `nh darwin switch` applies cleanly; spot-check each touched
      harness (opencode plugins, Claude guard, skills resolution).
- [ ] **Apply**: Stage changes and propose conventional-commit title(s), one
      concern per commit (do not commit unprompted).
