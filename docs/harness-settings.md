# Harness settings audit

Audit date: 2026-10-28. The inventory comes from
`~/.config/sysinit/agents.json`; native `--version` and `--help` were checked for
every entry. This audit covers configuration paths, supported settings, update
ownership, hook integration, and existing instruction/MCP discovery. It does not
change model selections, credentials, subscriptions, or active sessions. A help or
schema check does not establish that an authenticated model turn succeeds.

## Installed harnesses

| Harness | Installed version | Evidence and decision |
| --- | --- | --- |
| Amp | `0.0.1793145649-gaedc46` | Current settings pass Amp's official JSON schema; native help still supports the declared permission, update, remote-execution, and skill settings. Retain. |
| Claude Code | `2.1.312` | Native `doctor` finds no installation issues. Replace the ignored `dangerouslySkipPermissions` setting with `permissions.defaultMode = "bypassPermissions"`. Remove the redundant thinking-on default and the `disabledMcpServers` copy in settings; its existing `.claude.json` declaration remains. |
| Codex | `0.164.0` | Native strict startup configuration parsing succeeds. The pinned parser accepts but discards boolean `tools.web_search`; replace it with `web_search = "live"`. Install Nix-owned hooks through the native system config layer. |
| Copilot | `1.0.98` | Native settings reference rejects `theme = "auto"`; use `default`. The installed native parser accepts PascalCase command hooks. Replace the JavaScript extension shim with a native `PreToolUse` hook. |
| Crush | `0.98.2` | Current JSON configuration passes the schema from its installed release tag. Retain; upstream documents `crushrc`, but JSON remains supported. A format migration has no required behavior change here. |
| Cursor | `2026.10.01-e373342` | The installed loader honors `XDG_CONFIG_HOME/cursor/cli-config.json` on this machine, including macOS. Its native settings support our Vim, permission, and HTTP/1 settings. Retain the current path. |
| Devin | `3000.11.92` | Native `doctor --json` returns `ok: true`. It reports ignored metadata fields in user-created shared agent profiles. Retain the managed configuration and preserve those profiles. |
| fx | `0.0.15` | Native `status --json` reads the intended provider, model, and permission mode. Add `auto_upgrade = false` so Nix owns updates. |
| Antigravity (`agy`) | `1.4.1` | Native help and Google's settings schema support the current interface. Add managed CLI preferences for Vim editing, full-screen rendering, and terminal colors in `~/.gemini/antigravity-cli/settings.json`; preserve workspace trust and permission decisions. |
| Goose | `1.56.0` | Native `info` confirms the managed config and data paths. Retain the ACP provider registry, Codex ACP default, local memory, and code-execution extension configuration validated during the preceding update. |
| OpenCode | `2.2.0` | Retain the existing v2 settings renderer. Its repository check validates the main/CLI configurations against the schemas shipped with the installed package and checks unknown-key rejection. |
| Pi | `1.4.0` | Installed settings documentation supports every managed key, including code mode/tool search, full-screen UI, cache warming, and install telemetry. Retain owner-selected provider/model/thinking preferences. |
| Strands | `0.2.1` | The installed native profile and settings parsers accept the managed configuration and the existing `interventions=null` alias override. Retain skill discovery and explicit MCP discovery policy. |

The version column records the installed binaries, not a claim that every package
is the latest upstream release. Release and configuration documentation can be
newer than the pinned version; native behavior takes precedence for deployment.

## Hook ownership and trust

On nix-darwin and NixOS, `sysinit.codex.systemHooks.enable` defaults to the managed
user's Codex enablement. It installs the six Nix-owned hooks once in
`/etc/codex/hooks.json`. Codex identifies that source as system-managed and trusts
it by policy. The user configuration drops the old Nix-owned definitions through
its normal three-way reconciliation; hook trust state and unrelated runtime
settings remain writable.

The hook commands use the user's stable profile path. The Gate wrappers declare
the provider executables in their runtime dependencies, so they work with a minimal
caller `PATH`. Nix store hashes no longer appear in the Codex hook definitions.

Plugin and project hooks retain Codex's native review rules. This configuration
does not add the global hook-trust bypass flag. Standalone Home Manager profiles
without the system module keep user-layer hooks and their native review flow;
their profile-based commands remain stable across dependency updates.

Copilot uses the PascalCase `PreToolUse` format because its native adapter supplies
Claude-shaped `tool_name` and `tool_input` fields. The shared guard consumes that
shape. An explicit deny exits 2, which the native Copilot hook runner treats as a
deny. The replacement removes the SDK extension and its separate payload shim.

The `harness-settings` check exercises Copilot's real configuration parser and
the production guard with allow/deny fixtures under a minimal `PATH`. It also
evaluates Darwin and NixOS managed-hook placement. The other existing harness
checks remain the required validation gates.

## Limits and follow-up conditions

Claude's native doctor reports missing usable subscription credentials, and fx's
status reports that its selected Codex provider needs a login. Those findings limit
authenticated runtime verification; configuration changes do not sign in or reset
credentials. Devin's ignored shared-agent metadata is nonfatal and is
not rewritten by this audit. No active harness is restarted to adopt settings;
each client applies configuration through its supported reload or next-session
behavior.

## References

- [Codex hook sources and managed trust](https://learn.chatgpt.com/docs/hooks)
- [Claude settings reference](https://code.claude.com/docs/en/settings-reference)
- [Copilot native hooks](https://docs.github.com/en/copilot/reference/hooks-reference)
- [Amp settings and schema](https://ampcode.com/docs/cli/settings)
- [Crush v0.98.2 schema](https://github.com/charmbracelet/crush/blob/v0.98.2/schema.json)
- [Cursor CLI configuration](https://prod.cursor.com/docs/cli/reference/configuration)
- [fx configuration](https://fx.sh/docs/configure-fx/configuration)
- [Antigravity CLI settings](https://antigravity.google/docs/cli/reference/)
- [Pi settings](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/settings.md)
