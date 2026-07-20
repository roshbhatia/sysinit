# Design

## Decision 1: Slack gate becomes a deny hook, not a prompt

`dangerouslySkipPermissions = true` is retained (frictionless autonomous flow is
the intent for this personal config). Under skip there is no interactive
approval UI, so `permissions.ask` cannot function. The only mechanism that runs
under skip is a `PreToolUse` hook — proven by the existing `claude-bash-guard`.

Chosen behavior: a `PreToolUse` hook matched on the MCP Slack send tools returns
a `permissionDecision: "deny"` with a message telling the agent to ask the human
to send. This converts the intent from "prompt before send" to "block
autonomous send; human sends manually" — the only enforceable form under skip,
and the safer default for an outbound message tool.

Alternative considered and rejected: drop global `dangerouslySkipPermissions`
and rely on `permissions.allow` + `ask`. This restores the prompt but re-adds
approval friction for every command not on the allowlist. Rejected as too
disruptive for the day-to-day flow.

The dead `permissions.ask` entry is removed. The `permissions.allow` tiers stay
(documentation of intent; harmless under skip, load-bearing if skip is ever
dropped).

## Decision 2: Guard parity uses each harness's native mechanism

The destructive-command patterns are identical everywhere (force-push,
`--no-verify`/`--no-gpg-sign`, `reset --hard`, `clean -f`, `branch -D`). The
enforcement mechanism differs by what each tool supports natively — prefer
config over a new script wherever config suffices:

| Harness | Mechanism | Notes |
|---|---|---|
| Claude | `PreToolUse` hook (exists) | unchanged |
| Codex | `hooks.PreToolUse` command | port `claude-bash-guard.sh`; verify Codex's hook stdin field path (`tool_input.command` vs Codex shape) before wiring |
| Amp | `amp.permissions` deny entries | native `{tool, matches:{cmd}, action:"reject"}`; verify the reject action name against Amp's schema |
| opencode | `permission.bash` map | `{ "<pattern>" = "deny"; ... "*" = "allow"; }` |
| Goose | `shell.deny` regexes | `formatForGoose` currently emits `deny = []`; add the destructive patterns as regexes |

Crush is excluded: its `permissions` model is a flat `allowed_tools` list with no
per-command deny. Guarding Crush would need a plugin; out of scope here.

A shared source for the destructive patterns SHOULD live in `lib/allowlist.nix`
(a new `destructiveDenyPatterns` list) with per-harness formatters, mirroring the
existing tierA/tierB pattern, so the five harnesses stay in lockstep.

## Decision 3: opencode formatter migration

The top-level `formatter` key is `@deprecated` in favor of `lsp.<name>.formatter`.
`deadnix` is a nix linter, not an LSP. During apply, confirm opencode's current
schema for attaching a standalone formatter: either nest it under an `lsp.nix`
entry's `formatter` field, or confirm the top-level key still works and only the
schema annotation changed. Do not remove working behavior to satisfy an
annotation — verify the replacement renders and runs before deleting the old key.

## Decision 4: pi package swaps and load order

Derivation types (from package metadata):

- `pi-retry` (0 deps), `pi-vcc` (0 direct deps, 4 peers), `pi-sidebar-tui`
  (0 deps), `pi-rtk-optimizer` (peers only) → `mkFetchedNpmPackage` (plain fetch).
- `pi-web-access` (5 deps + 4 peers) → `mkBuiltNpmPackage` with a generated
  `./locks/pi-web-access.lock.json`, like the other dep-bearing packages.

Nix hashes (`sha256` + `npmDepsHash`) cannot be guessed; apply computes them via
`nix build` fail-and-fill (the repo's established flow for pi packages).

Load-order changes in `piPackagePaths` (comments updated to match):

1. Provider routing group: add `pi-retry` (provider-specific error
   classification, inert when providers behave).
2. Compaction: add `pi-vcc` early so its `session_before_compact` hook is
   registered; set `overrideDefaultCompaction = true` in
   `~/.pi/agent/pi-vcc-config.json`. The `trigger-compact` extension still fires
   the trigger; `pi-vcc` performs the compaction. Verify no double-compaction.
3. Tool providers: replace `webfetch` with `pi-web-access`; replace `rtk` with
   `pi-rtk-optimizer`.
4. UI/workflow: add `pi-sidebar-tui` (peer `pi-tui >= 0.74`, already satisfied).

## Decision 5: pi-web-access librarian overlap

`pi-web-access` bundles a `librarian` skill that overlaps the standalone
`pi-librarian` already installed. Keep `pi-librarian` (mature, standalone). If
both register a `librarian` and collide, disable the bundled one via
`pi-web-access` config (`~/.pi/web-search.json`) rather than dropping
`pi-librarian`.

## Decision 6: rtk binary dependency

`pi-rtk-optimizer` delegates command rewriting to an installed `rtk rewrite`
CLI. `pkgs.rtk` exists in the repo's nixpkgs pin, but "rtk" is an ambiguous
package name. Apply MUST confirm `pkgs.rtk` provides the `rtk rewrite`
subcommand before adding it to `home.packages`. If it is the wrong `rtk`, the
optimizer still runs (output compaction works; rewrite degrades to no-op) — but
do not add an unrelated `rtk` to PATH.

## Out of scope

- Claude `attribution` object, `footerLinksRegexes`, `personality`, `fastMode`,
  and Codex `memories`/`GOOSE_PLANNER_MODEL`/Goose recipes: optional niceties,
  not audit findings. Deferred.
- Cursor and Copilot: no defects found; AGENTS.md reliance and hooks parity are
  deferred.
- STE output style content is authored as a separate markdown file; this change
  wires the `outputStyle` setting and ships a first version, refinable later.
