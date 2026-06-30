# Design

## Context

Claude Code has three distinct plugin mechanisms, and the recurring annoyance comes from conflating two of them:

```
┌────────────────────────────────────────────────────────────────────────┐
│  THREE MECHANISMS — DIFFERENT JOBS                                       │
├──────────────────┬──────────────────────┬──────────────────────────────┤
│ marketplace      │ enabledPlugins       │ --plugin-dir                  │
│ (registration)   │ (persistent enable)  │ (local-dev override hatch)    │
├──────────────────┼──────────────────────┼──────────────────────────────┤
│ known_marketplaces│ settings.json       │ CLI arg, per-invocation       │
│ .json             │ "enabledPlugins"    │ no persistence                │
│ "where is it"     │ "load it everywhere"│ "load THIS dir right now"     │
└──────────────────┴──────────────────────┴──────────────────────────────┘
```

What the user does today: `claude --plugin-dir /nix/store/<hash>-claude-code-hm-plugin …`. Two problems live in that one habit:

1. The `--plugin-dir` path is the **home-manager inline plugin** (ast-grep + playwright MCP). The HM `claude` wrapper *already* injects this exact dir on every launch. So the manual flag is pure redundancy — and the store hash rotates each rebuild, which is why the saved snippet keeps breaking.
2. It has **nothing to do with Laurel**. Laurel (`laurel-eng`) is a marketplace plugin that needs registration + global enable, not a `--plugin-dir`.

So "I keep running `--plugin-dir` for my work plugins" is really two bugs wearing one coat: a redundant flag, and a missing persistent-enable for Laurel.

```
                       HM `claude` wrapper
                              │
        exec .claude-wrapped --plugin-dir <hm-inline-plugin> "$@"
                              │
   ┌──────────────────────────┴──────────────────────────┐
   │  user ALSO types: --plugin-dir <same hm-inline-plugin>│  ← redundant
   └───────────────────────────────────────────────────────┘

   Laurel is NOT here at all. It must come from:
        known_marketplaces.json (Laurel → directory)  +  settings.enabledPlugins
```

## Goals / Non-Goals

**Goals**
- On the work host (`Roshan-Bhatia-MacBook-Pro`), `laurel-eng` is enabled in every repo with zero per-invocation flags.
- Personal host (`lv426`) is byte-for-byte unaffected.
- Pure declarative path — no wrapper hacks, no shell-rc append, no runtime `/plugin install`.
- The work clone path never enters the Nix store / public repo (string path, directory source).

**Non-Goals**
- Auto-pulling the marketplace clone (directory source = operator runs `git pull`; documented in `marketplaces` option already).
- `laurel-biz`, `laurel-dataviz`, or any other plugin.
- Replacing or modifying the HM inline plugin / wrapper.

## Decisions

### Decision 1 — Add `enabledPlugins`, mirror upstream `extraKnownMarketplaces`

The upstream HM module already turns `marketplaces` into both `settings.extraKnownMarketplaces` and `known_marketplaces.json`. It does **not** expose a typed knob for `settings.enabledPlugins`. Rather than reach into `settings` ad-hoc at the host layer, add a first-class `sysinit.llm.claudeCode.enabledPlugins` option (symmetric with `marketplaces`/`plugins`) and have `claude.nix` translate it.

`settings.enabledPlugins` is a map of `"<plugin>@<marketplace>" → bool`. The option takes a list of keys and `claude.nix` lifts it:

```nix
# claude.nix, inside programs.claude-code.settings (gated on non-empty):
enabledPlugins = lib.genAttrs ccCfg.enabledPlugins (_: true);
```

Gating on non-empty keeps the key absent (not `{}`) on personal, so the emitted settings.json is identical to today there.

**Alternative considered — set `settings.enabledPlugins` directly in `hosts/default.nix`.** Rejected: it bypasses the option layer, duplicates the `@`-key convention inline, and breaks the established `marketplaces`/`plugins` symmetry that makes the host block readable.

**Alternative considered — keep using `--plugin-dir` via the `plugins` option pointed at the Laurel clone.** Rejected: `--plugin-dir` is a local-dev hatch with no global persistence semantics, loads the dir as a raw plugin (bypassing marketplace versioning/metadata), and is exactly the fragile habit we're removing. Per the CC changelog it's explicitly the override-for-development tool, not the enable mechanism.

### Decision 2 — Marketplace as a directory source over the local clone

`marketplaces.Laurel = "github/work/pinginc/ai-tooling"` (relative → resolved against `$HOME` by `resolvePath`). The upstream `mkMarketplaceEntry` writes `{ source = { source = "directory"; path = <resolved>; }; }`. String path, so the clone is never copied into the store.

This supersedes the current live `github`-source registration of `Laurel`. Directory source is the right call because:
- The clone is already maintained on the work box (the user pulls it).
- A github source would re-fetch and could drift from the locally-checked-out branch the user develops against.
- Keeps a single source of truth: the working tree at `~/github/work/pinginc/ai-tooling`.

```
hosts/default.nix (work host only)
   llm.claudeCode.marketplaces.Laurel = "github/work/pinginc/ai-tooling"
   llm.claudeCode.enabledPlugins      = [ "laurel-eng@Laurel" ]
            │                                   │
            ▼                                   ▼
   known_marketplaces.json            settings.json
   Laurel → { directory,              "enabledPlugins": {
              path: $HOME/github/        "laurel-eng@Laurel": true
              work/pinginc/ai-tooling }  }
            └───────────────┬───────────────┘
                            ▼
              every `claude` launch on work, all repos → laurel-eng loaded
```

### Decision 3 — Host gating is already free

`values.llm` flows to `sysinit.llm` via `modules/darwin/home-manager.nix` (`sysinit.llm = values.llm or { }`). Personal's `values.llm.claudeCode` has no `marketplaces`/`enabledPlugins`, so both default empty. No `isWork`/hostname conditional is introduced — the split is purely "work host fills the block, personal doesn't."

## Risks / Trade-offs

- **Read-only managed files.** On the work host, `~/.claude/settings.json` and `~/.claude/plugins/known_marketplaces.json` become read-only store symlinks. Using the in-app `/plugin` UI to toggle Laurel will fail or be reverted on next `switch`. *Mitigation:* this matches the repo's existing nix-managed-settings philosophy; enablement is intentionally a config change, not a runtime toggle. HM's `backupFileExtension = "backup"` preserves any pre-existing live files on first switch.
- **Stale runtime state.** Existing `installed_plugins.json` holds a project-local `Laurel@Laurel` v1.0.73. Once `enabledPlugins` drives a global enable of `laurel-eng@Laurel`, the stale record is harmless/superseded; not cleaning it by hand is deliberate (Non-goal).
- **Directory source requires manual pull.** No auto-update — acceptable and already documented on the `marketplaces` option.

## Migration / Rollout

1. Land the option + `claude.nix` wiring (inert on personal).
2. Fill the work host block.
3. On work: `nh darwin switch`, then `claude` in any repo and confirm `laurel-eng` is active (`/plugin` list, or check the rendered `settings.json` for `enabledPlugins`).
4. Drop the saved `--plugin-dir <hm-store-path>` snippet from muscle memory / any work notes — it's been redundant all along.

## Open Questions

- Should an optional host-gated alias bundle the user's habitual `--dangerously-skip-permissions`/`--ide` flags? Left as a follow-up (Non-goal here).
