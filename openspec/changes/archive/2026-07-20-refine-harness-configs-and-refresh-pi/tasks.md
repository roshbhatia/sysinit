# Tasks

## 1. Shared destructive-command patterns

- [x] **Apply**: Add a `destructiveDenyPatterns` list to `lib/allowlist.nix`
      (force-push, `push --force-with-lease`, `--no-verify`, `--no-gpg-sign`,
      `git reset --hard`, `git clean -f`/`-fd`, `git branch -D`) plus
      per-harness formatters: `formatDestructiveForAmp`,
      `formatDestructiveForOpencode`, `formatDestructiveForGoose`.
      Implemented as `destructiveDenyRegexes` (Goose/scripts) +
      `destructiveDenyGlobs` (opencode/Amp) with three formatters.
- [x] **Verify**: `nix-instantiate --parse lib/allowlist.nix` → PARSE OK.

## 2. Claude Code — Slack guard + settings

- [x] **Apply**: Add a `claude-slack-guard` `writeShellApplication`
      (`runtimeInputs = [ pkgs.jq ]`) that reads stdin, and if
      `.tool_name` is one of the three `slack_send_*` tools, prints a
      `permissionDecision: "deny"` JSON with a message telling the agent to ask
      the human to send. Wired into `settings.hooks.PreToolUse` with a matcher
      of the three tool names joined by `|`.
- [x] **Apply**: Remove `permissions.ask = llmLib.allowlist.slackSendTools`.
- [x] **Apply**: Add settings `fileCheckpointingEnabled = true`,
      `effortLevel = "high"`, `fallbackModel = [ "claude-sonnet-5" ]`,
      `alwaysThinkingEnabled = true`, `autoMemoryEnabled = true`; add
      `DISABLE_AUTOUPDATER = "1"` to `env`.
- [x] **Apply**: Add a custom output style file (generated from the STE
      `Communication` rules) under `~/.claude/output-styles/` and select it via
      `settings.outputStyle`.
- [x] **Verify**: Pipe sample JSON for a `slack_send_message` call (expect deny)
      and a `Read` call (expect silent pass) through the guard logic — PASS.
- [x] **Verify**: `nix flake check` passes (evaluated lv426 config).
- [ ] **Confirm**: After `nh darwin switch`, a Slack send is denied with the
      guidance message; checkpointing, effort, fallback, and thinking settings
      show in `/config`.

## 3. Codex — guard + web search

- [x] **Apply**: Confirmed via Codex hooks docs that its PreToolUse contract is
      identical to Claude's (`tool_input.command` payload,
      `permissionDecision:"deny"` output). Reused `claude-bash-guard.sh`
      verbatim as `codex-bash-guard`.
- [x] **Apply**: Wired the guard into `settings.hooks.PreToolUse` in `codex.nix`
      (not `async`; no matcher — script self-filters).
- [x] **Apply**: Enabled the built-in web-search tool (`tools.web_search = true`).
- [x] **Verify**: `nix flake check` passes (evaluated lv426 config).
- [ ] **Confirm**: After switch, a Codex `git push --force` is denied and
      `git status` runs; web search returns results.

## 4. Amp / opencode / Goose — guard

- [x] **Apply**: Amp — appended `formatDestructiveForAmp destructiveDenyGlobs`
      (action `reject`) to `amp.permissions`, before the catch-all allow.
- [x] **Apply**: opencode — merged `formatDestructiveForOpencode` deny entries
      into `permission.bash`, keeping `"*" = "allow"`.
- [x] **Apply**: Goose — `shell.deny` populated with `destructiveDenyRegexes`.
- [x] **Verify**: `nix flake check` evaluated all harness configs with deny entries.
- [ ] **Confirm**: After switch, a destructive command is blocked in Amp,
      opencode, and Goose; a benign command still runs.

## 5. Deprecation + consistency fixes

- [x] **Apply**: aider — set `attribute-co-authored-by = false` and
      `attribute-author = false` in `aider.nix`.
- [x] **Apply**: opencode formatter — verified against the opencode formatters
      docs that the top-level `formatter` key is NOT deprecated (the audit was
      wrong). deadnix config kept as-is; no migration. Artifacts corrected.
- [x] **Apply**: Goose — changed `GOOSE_MODE` from `"auto"` to `"smart_approve"`.
- [x] **Verify**: `nix flake check` passes (evaluated lv426 config).
- [ ] **Confirm**: aider commit has no co-author trailer; opencode still formats
      nix; Goose prompts on risk-assessed actions.

## 6. opencode + Crush — nix LSP

- [x] **Apply**: opencode — added `lsp.nixd` (`command = ["${pkgs.nixd}/bin/nixd"]`,
      `extensions = [".nix"]`); full store path, no PATH dependency.
- [x] **Apply**: Crush — added `lsp.nix` (`command`, `filetypes`, `root_markers`)
      pointing at `${pkgs.nixd}/bin/nixd`.
- [x] **Verify**: `nix flake check` evaluated both LSP blocks.
- [ ] **Confirm**: After switch, editing a `.nix` file surfaces `nixd`
      diagnostics in opencode and Crush.

## 7. pi — package swaps

- [x] **Apply**: Confirmed `pkgs.rtk` 0.43.0 provides `rtk rewrite` (help text:
      "single source of truth for hooks"). Added `pkgs.rtk` to `home.packages`.
- [x] **Apply**: Replaced `pi-rtk` with `pi-rtk-optimizer` v0.9.0
      (sha256-qlwpcoJe...). 
- [x] **Apply**: Replaced `webfetch` with `pi-web-access` v0.13.0 as an inline
      `buildNpmPackage` (its `@earendil-works/*` peers are pi-runtime-provided, so
      the lock omits them via `--package-lock-only --legacy-peer-deps` and the
      build passes `--legacy-peer-deps`). tarball sha256-6d/cX9...,
      npmDepsHash sha256-8onTvv...; generated `./locks/pi-web-access.lock.json`;
      removed the dead webfetch lock. Isolated build succeeds.
- [x] **Apply**: Added `@narumitw/pi-retry` v0.22.0 (sha256-TwMvcJ...) and
      `pi-sidebar-tui` v1.3.1 (sha256-WiKgy0...).
- [x] **Apply**: Added `@monotykamary/pi-vcc` v0.8.1 (sha256-hsk/cw...); wrote
      `~/.pi/agent/pi-vcc-config.json` with `overrideDefaultCompaction = true`.
- [x] **Apply**: Updated `piPackagePaths` order and comment block.
- [x] **Apply**: Updated `./hack/update-pi.sh` TRACKED list and KNOWN_LOCKS.
- [x] **Verify**: pi-web-access built in isolation; each fetchNpmPkg hash proven by its fetch; flake check evaluated pi.nix.
- [x] **Verify**: `nix flake check` passes.
- [ ] **Confirm**: After switch, pi loads without error; sidebar renders; web
      search works; compaction fires once (no double compaction with
      `trigger-compact`); `pi-librarian` still works without collision.

## 8. Validate + apply

- [x] **Verify**: `openspec validate refine-harness-configs-and-refresh-pi` — valid.
- [ ] **Confirm**: `nh darwin switch` applies cleanly; spot-check each touched
      harness launches.
- [ ] **Apply**: Stage changes and propose conventional-commit title(s), one
      concern per commit (guard, claude-settings, deprecation-fixes, pi-packages).
