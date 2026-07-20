## Why

An audit of every agent harness in `modules/home/programs/llm/` against each
tool's current settings schema found one behavior bug, several deprecated or
inconsistent keys, and unused high-value capabilities. The prior change
`upgrade-agent-harnesses-mid-2026` shaped the harnesses; this change closes the
gaps that audit surfaced and refreshes the pi package set.

Concrete findings:

- **Claude Code Slack gate is inert (bug).** `dangerouslySkipPermissions = true`
  bypasses `permissions.allow`, `ask`, and `deny` alike. So
  `permissions.ask = slackSendTools` never fires — Slack sends are not gated.
  A `PreToolUse` hook is the only mechanism that still runs under skip (it is how
  the existing bash guard works).
- **The destructive-command guard exists only in Claude Code.** Codex, Amp,
  opencode, and Goose run allow-all / auto with no mechanical block, so the
  global CLAUDE.md prohibitions (no force-push, no `--no-verify`, no
  `reset --hard`, no `clean -f`, no `branch -D`) are unenforced on those four.
- **aider stamps commits against policy.** aider defaults
  `attribute-co-authored-by = true` and `attribute-author = true`; every other
  harness suppresses co-authorship. aider is inconsistent.
- **opencode formatter form (verified current).** An earlier audit flagged the
  top-level `formatter` key as deprecated; the opencode formatters docs confirm
  it is the current documented method. No migration — recorded to close the
  finding.
- **Unused capabilities.** Codex has web search available but disabled; opencode
  and Crush configure no LSP servers (no live diagnostics); Goose runs blanket
  `auto` instead of the risk-assessed `smart_approve`.
- **Claude Code high-value settings unset.** File checkpointing, persisted
  effort level, fallback model, always-on thinking, explicit auto-memory, and
  autoupdate-off (for Nix reproducibility parity with every other harness) are
  all available and unset.
- **pi package set is stale.** `pi-rtk` (v0.1.4) is superseded by the mature
  `pi-rtk-optimizer` (v0.9.0); `pi-webfetch-to-markdown` is a subset of the
  far more mature `pi-web-access` (adds web search — a real capability gap);
  and three low-risk packages (`pi-retry`, `pi-vcc`, `pi-sidebar-tui`) add
  resilience, deterministic compaction, and a session sidebar.

These are config-and-package refinements to existing harnesses — no new harness.

## What Changes

### Claude Code

- Replace the inert `permissions.ask` Slack gate with a `PreToolUse` hook that
  mechanically denies the three `slack_send_*` MCP tools and instructs the agent
  to have the human send. Remove the dead `permissions.ask` entry.
- Add documented settings: `fileCheckpointingEnabled = true`,
  `effortLevel = "high"`, `fallbackModel = ["claude-sonnet-5"]`,
  `alwaysThinkingEnabled = true`, `autoMemoryEnabled = true`, and
  `DISABLE_AUTOUPDATER = "1"` in `env` (Nix owns updates, matching every peer
  harness). Add a custom output style that encodes the STE Communication rules.

### Cross-harness destructive-command guard

- Extend the mechanical guard to the four unguarded harnesses using each tool's
  native mechanism (no new interpreter where config suffices):
  - Codex: `hooks.PreToolUse` command hook (port of `claude-bash-guard.sh`,
    adapted to Codex's hook payload shape).
  - Amp: `amp.permissions` deny entries for the destructive command patterns.
  - opencode: `permission.bash` map with deny patterns.
  - Goose: `shell.deny` regex patterns (currently empty).

### Deprecation and consistency fixes

- aider: set `attribute-co-authored-by = false` and `attribute-author = false`.
- opencode: migrate the deprecated top-level `formatter` to `lsp.<name>.formatter`.
- Goose: change `GOOSE_MODE` from `auto` to `smart_approve`.

### Unused-capability adds

- Codex: enable the built-in web-search tool.
- opencode and Crush: add a `nix` LSP server (`nixd`) for live diagnostics.

### pi packages

- Replace `pi-rtk` (v0.1.4) with `pi-rtk-optimizer` (v0.9.0); verify the
  nixpkgs `rtk` binary provides `rtk rewrite`.
- Replace `pi-webfetch-to-markdown` (v1.0.1) with `pi-web-access` (v0.13.0);
  keep `pi-librarian` and disable the bundled librarian skill if it conflicts.
- Add `@narumitw/pi-retry` (v0.22.0), `@monotykamary/pi-vcc` (v0.8.1) with
  `overrideDefaultCompaction` coordinated against the `trigger-compact`
  extension, and `pi-sidebar-tui` (v1.3.1).
- Do NOT add `pi-lens` (43.7 MB, auto-installs external tools — conflicts with
  Nix reproducibility and the "avoid global installers" prohibition),
  `@ogulcancelik/pi-codex-subagents` (less mature than incumbent `pi-subagents`),
  or `@normful/pi-show-files-read` (redundant with `pi-tool-display` and
  `pi-sidebar-tui`).
