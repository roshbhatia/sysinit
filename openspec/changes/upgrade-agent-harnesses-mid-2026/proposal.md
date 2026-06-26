## Why

The agent-harness layer (`modules/home/programs/llm/`) was last shaped before a
cluster of mid-2026 ecosystem shifts that this repo has not yet absorbed:

- **Claude Code 2.1.187** ships a documented destructive-action block list and
  a `PreToolUse` hook event, but the config has zero `PreToolUse` gates — the
  global-CLAUDE.md prohibitions (no `--no-verify`, no `reset --hard`, no
  force-push) are honored only by convention, never mechanically enforced.
  Checkpoints/rewind cover Write/Edit but NOT bash side effects.
- **opencode/Crush/Amp now read `~/.claude/skills` natively**, yet the rendered
  instruction text points opencode at `~/.config/opencode/skills` and Crush at
  `~/.config/crush/skills` — directories that contain **no SKILL.md files**
  (skills install only to `~/.claude/skills/`, per `default.nix`). Those two
  harnesses currently advertise an empty skills root.
- The two-tier (strong-reasoner + cheap-helper) model split that every peer
  tool converged on is unset for opencode and Crush.
- `claude.nix` carries `autoCompactWindow`, an undocumented key; the documented
  control is `autoCompactEnabled`.
- Claude Code's experimental **Agent Teams** / **Dynamic Workflows** multi-agent
  orchestration is available but not opted into.
- The **Gemini CLI was retired 2026-06-18** (it stopped serving requests for
  Pro/Ultra/free tiers). Its successor is the Go-based **Antigravity CLI**
  (`agy`), which is already packaged as `pkgs.antigravity-cli` (1.0.7) in this
  repo's nixpkgs pin. `gemini.nix` targets a dead binary and should migrate.
- opencode gained four high-value plugins (codex-auth, pty, vibeguard,
  md-table-formatter) not yet declared.

These are config-and-workflow upgrades to existing harnesses — no new harness,
no new package overlay.

## What Changes

### opencode plugins (already applied)

- Add four plugins to `config/opencode.nix` `plugin` array:
  `opencode-openai-codex-auth@latest` (ChatGPT-sub auth, OpenAI peer to the
  existing gemini-auth), `opencode-pty` (PTY tools for interactive/long-running
  processes), `opencode-vibeguard` (redact secrets before they leave for the
  provider), `@franlol/opencode-md-table-formatter@latest` (re-align markdown
  tables in output; opencode 1.17.7 ≫ its 1.0.137 floor).

### Claude Code destructive-command guard (new behavior)

- Add a `PreToolUse` hook matching `Bash` that **denies** the commands the
  global CLAUDE.md prohibits unconditionally: force-push, any `--no-verify` /
  `--no-gpg-sign` hook-bypass flag, `git reset --hard`, `git clean -f`,
  `git branch -D`, force-with-lease pushes. The hook reads `tool_input.command`
  on stdin and returns a structured deny decision. Implemented as a shared
  `pkgs.writeShellApplication` script wired through `claude.nix` hooks,
  mirroring the existing `notify.exe` pattern.
- This is the mechanical floor under the prohibitions; the `allow`/`ask` tiers
  are unchanged. `auto` permission mode is deliberately NOT adopted (its default
  block list also blocks push-to-`main`, which this repo permits).

### Skills-root unification (correctness fix)

- Change the `mkInstructions` skills-root argument for opencode and Crush from
  their phantom per-tool paths to `~/.claude/skills`, the directory both read
  natively and where SKILL.md files actually install. No new files; the skills
  tree is consumed verbatim by Claude Code, opencode, Crush, and Amp.

### Two-tier model config

- Set opencode `small_model` and Crush `models.small` to a cheap helper model
  (Haiku-class) for summarization/title/cheap-edit work, keeping the strong
  reasoner as the large/default. Mirrors `aider.nix`'s existing
  architect + `editor-model` split.

### Documented-key cleanup

- Replace `autoCompactWindow` (undocumented) in `claude.nix` with the
  documented `autoCompactEnabled`; re-verify or annotate `autoDreamEnabled`.

### Experimental multi-agent orchestration (opt-in)

- Export `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` so Agent Teams is available,
  and document the Dynamic Workflows usage pattern in this change's design.

### Gemini → Antigravity (`agy`) migration

- Migrate `gemini.nix` from the retired `pkgs.gemini-cli` to
  `pkgs.antigravity-cli` (`agy`). Concretely: swap the package; move MCP server
  declarations from `~/.config/gemini/settings.toml` (TOML) to agy's JSON
  `~/.gemini/config/mcp_config.json` (reusing an existing JSON MCP formatter
  from `lib/mcp.nix` rather than the TOML `formatForGemini`); rely on agy's
  native `AGENTS.md` reading for context (the May-2026 standard this repo
  already generates), keeping a legacy `GEMINI.md` write only if needed; and
  re-home the single `openspec-awareness` extension as an agy plugin.
- **The first task is a Verify step that builds `pkgs.antigravity-cli` and
  inspects the real binary's config surface** (`agy --help`, actual
  `mcp_config.json` schema, whether `/skills` reads `~/.claude/skills`) —
  because the config shapes above come from third-party cheatsheets, not
  primary docs, and must be confirmed before the Nix is written.

### Non-goals

- **No `auto` permission mode.** Its default block list blocks push-to-`main`,
  which this repo permits; the `PreToolUse` hook delivers the same destructive
  protection without that friction.
- **No bash sandbox / `sandbox.credentials`.** Enabling the sandbox changes the
  execution environment of every bash call; out of scope for this pass.
- **No new agy features beyond parity.** The migration ports the existing
  Gemini setup (MCP, context, the one extension) to `agy`; agy-specific
  capabilities (subagents framework, hooks, plugin marketplace, non-Gemini
  models) are out of scope for this pass.
- **No Codex sandbox `network_access` change.** Tied to sandbox adoption, which
  is out of scope.
- **No new MCP servers.** ast-grep + playwright are unchanged.
- **No new subagents.** The oracle/code-reviewer/librarian/implementor set is
  unchanged; built-in Plan/Explore cover planning and search.

## Capabilities

### New Capabilities

- `claude-destructive-command-guard`: declares that Claude Code mechanically
  denies a fixed set of irreversible/hook-bypassing bash commands via a
  `PreToolUse` hook, independent of the conversational permission tiers, and
  that the deny set is sourced from the global CLAUDE.md prohibitions.
- `antigravity-cli-harness`: declares that the Gemini-family harness is the
  Antigravity CLI (`agy`, `pkgs.antigravity-cli`) rather than the retired
  Gemini CLI, configured declaratively via home-manager with MCP servers,
  shared `AGENTS.md` context, and the openspec extension ported as an agy
  plugin.

### Modified Capabilities

- `agent-skill-portability`: the skills tree installed at `~/.claude/skills`
  is the single root advertised to every harness that reads it natively
  (Claude Code, opencode, Crush, Amp); no harness advertises a skills root that
  contains no skills.
