# Design

## Context

All edits land in `modules/home/programs/llm/`. The harness configs are
generated; the shared `mkKit` / `lib/instructions.nix` / `lib/allowlist.nix`
layer is unchanged except where noted. Doc contracts below were verified
against live Claude Code docs (2.1.187) on 2026-06-26.

## Decision 1 — Destructive-command guard via PreToolUse hook (not `auto` mode)

`auto` permission mode ships a built-in destructive block list, but that list
also blocks pushing to `main` — which this repo explicitly permits (memory:
"sysinit repo: commit/push straight to main"). So `auto` is rejected; a
purpose-built `PreToolUse` hook gives the same protection without the friction.

**Verified hook contract** (`https://code.claude.com/docs/en/hooks.md`):

- Matcher: `"Bash"`.
- stdin JSON includes `tool_name` (`"Bash"`) and `tool_input.command` (the
  command string), plus `session_id`, `cwd`, `permission_mode`, etc.
- Deny via stdout JSON (exit 0):
  ```json
  {
    "hookSpecificOutput": {
      "hookEventName": "PreToolUse",
      "permissionDecision": "deny",
      "permissionDecisionReason": "<which prohibition was violated>"
    }
  }
  ```
  `permissionDecision` ∈ {allow, deny, ask, defer}.
- Alternative: exit code 2 + message on stderr (stdout JSON ignored). We use
  the structured stdout form so the reason reaches the user cleanly; exit 2 is
  the fallback only if the JSON form misbehaves.

**Implementation shape.** A `pkgs.writeShellApplication` (named e.g.
`claude-bash-guard`) reads stdin, extracts `.tool_input.command` with `jq`,
matches it against the deny patterns, and prints the deny JSON when hit —
otherwise prints nothing and exits 0 (passes through to the `allow`/`ask`
tiers). Wired into `claude.nix` `settings.hooks.PreToolUse` with
`matcher = "Bash"`, mirroring the existing `notify.exe` wiring. Not `async`
(a deny must resolve before the tool runs).

**Deny patterns** (extended-regex against the command string; both spaced and
combined short-flag forms):

```
git push .*(--force|--force-with-lease|-f)\b
(--no-verify|--no-gpg-sign)\b
git reset .*--hard\b
git clean .*-[a-z]*f\b
git branch .*-D\b
git branch .*--delete .*--force\b
```

Plain `git push` / `git push origin main` does NOT match → push-to-main stays
allowed. Matching is intentionally conservative (deny on clear hits) to avoid
false positives on unrelated commands; the conversational tiers remain the
catch-all.

```
            stdin JSON {tool_name, tool_input.command, ...}
                              │
                      ┌───────▼────────┐
                      │ claude-bash-   │
                      │ guard (jq +    │
                      │ regex match)   │
                      └───┬────────┬───┘
                  match   │        │  no match
                          ▼        ▼
              deny JSON on stdout   (silent, exit 0)
              → tool blocked        → allow/ask tiers decide
```

## Decision 2 — Skills-root unification

`default.nix` installs SKILL.md files ONLY under `~/.claude/skills/`. opencode
and Crush read that tree natively, yet `opencode.nix` passes
`~/.config/opencode/skills` and crush passes `~/.config/crush/skills` to
`mkKit.mkInstructions` — phantom dirs with no skills. Fix: pass
`"~/.claude/skills"` for both, matching what claude/codex/gemini/aider/hermes
already do. One-arg change per file; no new files, no skill duplication.

## Decision 3 — Two-tier models

opencode supports `small_model`; Crush supports `models.small`. Both currently
unset, so the strong default does cheap summarization/title work. Set a
Haiku-class helper as the small model, keeping the strong reasoner as default —
mirrors `aider.nix`'s architect + `editor-model` split. Exact model IDs are an
Apply-time detail (read the current default to pick the matching cheap tier).

## Decision 4 — Documented-key cleanup in claude.nix

| Key                 | Status (verified 2026-06-26)                        | Action |
|---------------------|-----------------------------------------------------|--------|
| `autoCompactWindow` | Undocumented; no documented threshold setting exists | Remove |
| `autoCompactEnabled`| Documented: Boolean, default `true`, min v2.1.119    | Set explicitly (`true`) or drop and rely on default |
| `autoDreamEnabled`  | Absent from docs                                     | Remove, or keep with an explicit "undocumented, verify via /config" comment |
| `tui = "fullscreen"`| Absent from public reference                         | Keep (known-good internal key, already commented) |

There is NO documented replacement for `autoCompactWindow`'s 145000 threshold —
the threshold is not tunable. Net: drop `autoCompactWindow`; either drop
`autoCompactEnabled` (default already `true`) or set it explicitly for intent.
Treat `autoDreamEnabled` like `tui` if kept (comment as unverified), else drop.

## Decision 5 — Experimental orchestration (opt-in, zero-risk)

- **Agent Teams**: set `settings.env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1"`
  in `claude.nix` (verified: env-var-in-settings is a supported enablement
  path). Gives lead+teammates as independent sessions with a shared task list
  and inter-agent messaging — strictly additive; nothing changes until used.
- **Dynamic Workflows**: verified to need NO configuration — available by
  default, opt-in by usage (`ultracode` keyword / asking Claude to write one).
  Captured here as documentation only; no settings change. (Could later set
  `disableWorkflows` if we ever want it off — we don't.)

## Decision 6 — Gemini → Antigravity CLI (`agy`) migration

Gemini CLI was retired 2026-06-18; its successor is the Go-based Antigravity
CLI (`agy`), already in this repo's nixpkgs pin as `pkgs.antigravity-cli`
(1.0.7). Since freezing a dead binary has no upside, `gemini.nix` migrates to
`agy`.

**Config-surface delta** (from third-party docs — MUST be confirmed against the
built binary in the first task before any Nix is written):

| Concern | Gemini CLI (now)                         | Antigravity `agy` (target)                         |
|---------|------------------------------------------|----------------------------------------------------|
| package | `pkgs.gemini-cli`                        | `pkgs.antigravity-cli`                             |
| settings| `~/.config/gemini/settings.toml`         | `~/.gemini/antigravity-cli/settings.json` (JSON)   |
| MCP     | `[mcpServers]` in settings.toml (TOML)   | `~/.gemini/config/mcp_config.json` (JSON)          |
| context | `~/.config/gemini/GEMINI.md`             | native `AGENTS.md` (+ legacy `GEMINI.md` honored)  |
| extras  | `~/.gemini/extensions/<name>/`           | plugins (`agy plugin install` / `import gemini`)   |
| auth    | Google account                           | system keyring + Google Sign-In (SSH-aware)        |

**Implementation notes.**

- The MCP write flips TOML→JSON. `lib/mcp.nix` already has JSON formatters for
  other harnesses; reuse the closest-matching one (likely the generic
  `{command,args,env}` shape) rather than adding a formatter. Confirm agy's
  actual key names from the built binary first.
- agy reads `AGENTS.md` natively (the standard this repo already generates via
  `instructions.nix`), so the per-tool `GEMINI.md` write may be droppable;
  decide at Apply time based on whether agy picks up the global `AGENTS.md`
  without a per-tool copy.
- The single `gemini-extensions/openspec-awareness` extension re-homes as an
  agy plugin. There is no curl-installer path acceptable here (reproducibility);
  vendor the plugin's files declaratively under the agy plugin dir, the same
  way `gemini.nix` currently installs extension files verbatim. If agy's plugin
  manifest differs from `gemini-extension.json`, translate it.

**Why not freeze.** The earlier scoping considered freezing `gemini.nix`. The
user chose migration: the package exists in nixpkgs, so the only real unknown
is the exact JSON/plugin schema — resolved by inspecting the binary, not by
deferring. Migrating now also keeps the Gemini-family harness alive instead of
shipping a binary that no longer serves requests.

**Risk.** The config shapes are sourced from third-party cheatsheets; the first
task gates the whole slice on confirming them against `pkgs.antigravity-cli`
itself. If the binary's surface diverges materially, the slice re-scopes before
any irreversible config change.

**Gate verification — confirmed against the built binary (`antigravity-cli`
1.0.7, `bin/agy`, inspected via `--help`, subcommand help, string table, and a
sandboxed `HOME` launch).** The surface does **not** diverge materially; the
table above holds, with these refinements:

- **Binary**: single Go binary `bin/agy` (~138 MB). Subcommands: `models`,
  `plugin`/`plugins`, `install`, `update`, `changelog`, `help`. Flags include
  `--print`/`-p`, `--prompt`, `--continue`/`-c`, `--model`, `--sandbox`,
  `--dangerously-skip-permissions`, `--add-dir`.
- **Package is UNFREE** (new finding). `lib/builders/pkgs.nix` sets
  `allowUnfree = true` but ALSO an `allowUnfreePredicate` that only permits
  `_1password-gui` — the predicate wins, so `antigravity-cli` is denied until
  `"antigravity-cli"` is added to that list. This is a required Apply step the
  original table omitted.
- **MCP**: confirmed `~/.gemini/config/mcp_config.json` (auto-created empty on
  first launch). Top-level key is `mcpServers` (standard Claude-shape JSON), with
  per-server fields `command`/`args`/`env` (stdio) and `url`/`httpUrl`/`type`/
  `transport`/`timeout` (http). `lib/mcp.nix`'s `formatForClaude` already emits
  exactly this per-server shape — wrap it as `{ mcpServers = … }`; no new
  formatter needed. (`formatForClaude` also adds `description`/`enabled`, which
  agy tolerates as unknown fields.)
- **Settings dir**: `~/.gemini/antigravity-cli/` (holds `keybindings.json`,
  `installation_id`, `log/`, `cache/`, `knowledge/`, `conversations/`,
  `builtin/`). `settings.json` is read-if-present, not auto-written, so no
  managed settings.json is required for the migration.
- **Context**: both `AGENTS.md` (4 refs) and `GEMINI.md` (2 refs) are read
  natively → the per-tool `GEMINI.md` write can be dropped; agy picks up the
  repo `AGENTS.md`.
- **Plugins**: manifest is `plugin.json` (Claude-style), and `agy plugin import`
  pulls "from gemini **or claude**" with legacy `gemini-extension.json` still
  parsed. The `openspec-awareness` extension re-homes as an agy plugin.
- **Auth**: "Launch the CLI without arguments to sign in"; OAuth tokens at
  `~/.gemini/antigravity-cli/.../mcp_oauth_tokens.json` — keyring + Google
  Sign-In as expected.

## Risks / Trade-offs

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| Guard regex false-positive blocks a legitimate command | Low | Patterns target unambiguous destructive flags; conversational tiers unaffected; easy to refine the regex |
| Guard regex false-negative (obfuscated command slips through) | Med | Guard is a floor, not a sandbox; this is acceptable for a single-user trusted-operator setup. Documented as best-effort |
| `jq` not on hook PATH | Low | Bundle `jq` in the `writeShellApplication` `runtimeInputs`, as `worklogScript` does for its inputs |
| opencode/Crush stop finding skills after path change | Low | Change points them AT the populated dir; verify a known skill resolves post-switch |
| New opencode plugins clobber existing ones | Resolved | 4 added are disjoint from the 4 existing; the 2 skipped (jenslys gemini-auth = dup, shell-strategy = instructions-not-plugin + conflicts pty) were excluded |
| Small-model ID drifts from provider availability | Low | Pick the cheap tier matching the current default at Apply time; pin explicitly |
| Agent Teams / Workflows are experimental and may change | Accepted | Both are additive opt-ins; no workflow depends on them |

## Migration / Rollout

All changes are home-manager config. Rollout is `nh darwin build` (verify) then
`nh darwin switch` (apply). `nix flake check` and `nix fmt` gate the commit. No
data migration; the guard takes effect on the next Claude Code session.
