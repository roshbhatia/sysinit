## Context

The pi integration lives at `modules/home/programs/llm/config/pi.nix` and is the largest config file in the LLM module — 465 lines covering an upstream-TS-vendoring block, a Nix-helper layer for fetching npm packages (`fetchNpmPkg` / `buildNpmPkg`), a 16-package vendoring table, a stylix-driven theme, two standalone CLI derivations (`piAcp`, `piCosts`, `nvimPi`), and an activation script that merges Nix-managed settings into pi's runtime `settings.json`. The pattern is well-established and works; the problem is freshness, not architecture.

The same module already demonstrates the conflict-resolution lever we need: the `pi-tool-display/config.json` block (line 444) explicitly hands tool ownership to `pi-diff` for `edit`/`write` while keeping it with `pi-tool-display` for `read`/`grep`/`find`/`ls`/`bash`. We extend that same pattern to handle permission-system vs confirm-destructive.

The custom extension we ship is the first time we author a pi extension ourselves rather than vendoring one. The pattern to follow is the upstream TS file shape (single default export, registers via the pi extension API), placed alongside the vendored extensions in `~/.pi/agent/extensions/`. Pi's extension loader picks up every `.ts` file in that directory; nothing extra needs wiring.

Constraints:
- Single-user dotfiles; no multi-host conditional behavior expected.
- Pi loads packages via local store paths in `settings.json` `packages` — peer-dep mismatches between `@mariozechner/pi-coding-agent` (pre-rename) and `@earendil-works/pi-coding-agent` (post-rename) are advisory at install time but become hard breaks if an extension's TS source actually imports from a specific scope.
- 5 of the 10 new packages still peer on the old `@mariozechner` scope; the other 5 use the new `@earendil-works` scope. All were inspected and chose to keep the old peer name out of inertia, not because they import from it (verified by reading package.jsons; none of them have `dependencies` pulling the pi-coding-agent package directly).
- `~/.pi/agent/settings.json` is partially user-owned (session state) and partially Nix-managed (`packages`, `quietStartup`, `showLastPrompt`). The activation script uses `jq '.[0] * .[1]'` to merge with Nix-side wins on conflict.

## Goals / Non-Goals

**Goals:**

- One source of truth (`pi.nix`) for everything pi consumes: extension TS files, npm packages, CLI tools, theme, and settings.
- 10 new packages integrated without regressing any currently-working capability.
- Pi's status line shows the active openspec change name and progress, so the user sees spec-driven state in the agent's chrome.
- Future drift detection takes one command (`./hack/update-pi.sh`).
- Conflict resolution between permission-system and confirm-destructive happens at the Nix layer, not at pi runtime.

**Non-Goals:**

- A two-way bridge (pi mutating openspec state). Out of scope here; revisit after read-only usage period.
- Per-host or per-machine conditional extension loading. The dotfiles are single-user; no need.
- Automating `nh darwin switch` from `update-pi.sh`. The schema's rollout gate explicitly requires a verify step before apply.
- Reproducing pi extension authoring patterns (TS API typing, testing) — the openspec-status extension is small enough to inline-comment.

## Decisions

### D1. Vendoring stays at registry tarball + Nix `buildNpmPackage`

**Decision:** Keep the existing `fetchNpmPkg` / `buildNpmPkg` helpers; do not switch to `npmlock2nix`, `node2nix`, or pi's own `pi-depo` package manager.

**Alternatives considered:**
- *`npmlock2nix` from `nix-community`:* would let us point at a single lock file per package. Adds a flake input, changes the build graph, and obscures the per-package hash provenance.
- *`pi-depo`:* pi's native meta package-manager. Directly conflicts with our Nix-managed model — we'd lose reproducibility and atomic system state. Rejected.
- *Bun via `bun install` at runtime:* not reproducible from Nix store, requires runtime network access.

**Why keep:** the existing pattern proves we can vendor 16 packages reliably; bumping the count to 26 changes nothing in the build graph. The helpers themselves are <30 lines of Nix.

### D2. Conflict resolution between `confirm-destructive` and `@gotgenes/pi-permission-system`

**Decision:** When `@gotgenes/pi-permission-system` is in the package list, the `confirm-destructive` upstream-vendored extension MUST be removed from `pi.nix`'s `extensions` array. Encoded as a build-time assertion in `pi.nix`.

**Alternatives considered:**
- *Keep both, let the user disable one via runtime config:* invites silent double-prompting and is not "single source of truth".
- *Always disable confirm-destructive (even without permission-system) and rely on git-checkpoint + reverse-last:* loses the simple destructive-action gate when permission-system rules haven't been configured yet.
- *Disable permission-system unless explicitly enabled:* leaves the more capable gate unused by default.

**Why this resolution:** the user is opting into permission-system explicitly via this change; matching that decision with the disablement of confirm-destructive avoids the worst failure mode (silent double-prompting) while keeping a strong gate.

### D3. Load order encoded as `packages` array order

**Decision:** Express load-order constraints as the order of the `packages` array in the generated `settings.json`. Group:
1. Permission enforcement (loaded first, wraps tool calls)
2. Provider routing (`@benvargas/*`)
3. Orchestration (`pi-subagents`, `taskplane`)
4. Memory + advisor (`@samfp/pi-memory`, `@juicesharp/rpiv-advisor`)
5. UI + workflow (`@plannotator/pi-extension`, `pi-btw`, `@firstpick/pi-extension-reverse-last`)
6. Tool providers (`pi-tool-display`, `@heyhuynhgiabuu/pi-diff`, `pi-dcp`, `pi-webfetch-to-markdown`, `pi-mcp-adapter`)
7. Content utilities (`pi-context`, `pi-subdir-context`, `pi-readline-search`, `pi-rtk`, `pi-threads`, `pi-interview`, `pi-librarian`, `pi-ask-user`, `pi-annotated-reply`, `pi-mermaid`)

**Alternatives considered:**
- *Hash-keyed sets:* pi loads packages in array order; using attrsets would lose ordering.
- *Topological sort via Nix:* over-engineering for a stable list maintained by hand.

**Why array order:** simple, visible, and matches how pi actually loads.

### D4. openspec-status extension is read-only first

**Decision:** Ship a strictly read-only extension. No tool registration, no event-bus interception, no shell-out beyond `openspec list --json` and `openspec status --change <name> --json`. Status-line item only.

**Alternatives considered:**
- *Gate writes when no change is active:* powerful, but premature without lived experience of the read-only version. Easy to add later.
- *Slash command `/openspec` that runs `openspec list`:* duplicates the bash a user can already run; agent would rather invoke `openspec` directly.
- *Skip the extension entirely; rely on the CLI in the message stream:* loses the always-visible nudge.

**Why read-only:** smallest blast radius for the highest-value visibility. Follows the schema's "progressive rollout" rule.

### D5. Drift script is shell + curl + jq, not Nix-based

**Decision:** `hack/update-pi.sh` is a bash script using `curl` for npm registry queries, `jq`/`python3 -c` for parsing, and the fake-hash technique for `nix build` retries. No `nvfetcher` or other framework.

**Alternatives considered:**
- *`nvfetcher`:* a real solution to update-script-fatigue. Adds a flake input and a versioning toml. Worth considering project-wide but out of scope for this change.
- *Embed update logic in Nix:* not possible without impure evaluation; bad pattern.

**Why bash:** matches `hack/update-openspec.sh` and `hack/update-claude-code.sh`. Easy to extend, easy to read, no new dependencies.

### D6. Provider-coupled extensions ship unconditionally

**Decision:** `@benvargas/pi-claude-code-use`, `@benvargas/pi-openai-fast`, `@benvargas/pi-openai-verbosity` are all installed regardless of which provider is active in a given session. Each is inert when its provider isn't in use.

**Alternatives considered:**
- *Conditional on a `programs.pi.provider` option:* introduces a new options surface we don't need yet. Single-user dotfiles can flip provider per-session.
- *Install only `claude-code-use`:* user uses both Anthropic and Codex; installing only one closes a door.

**Why install all:** inertness when irrelevant means there's no cost beyond a few hundred extra bytes in `~/.pi`.

### D7. piExtensionsRev bumps follow `nix flake update` cadence, not extension changes

**Decision:** The `piExtensionsRev` is bumped in this change to a recent main commit, then treated like a normal flake input — updated by `nix flake update` cadence and the `hack/update-pi.sh` drift script, not opportunistically.

**Alternatives considered:**
- *Auto-bump on every build:* breaks reproducibility.
- *Pin to a release tag:* upstream `earendil-works/pi` does cut tags but very frequently (one per commit on main). Rev-pinning is more stable.

**Why a rev:** matches the existing pattern in `pi.nix` and gives one place to look when something breaks.

## Rollout & Gating

**Sequenced rollout** (default for dotfiles work):
1. **Slice 1 — pin refresh.** Update the renamed source rev, bump npm pins, delete orphan lockfile, refresh theme URL.
2. **Gate 1.** `nix flake check`, `nh os build --no-link`, user spot-checks `git diff` of `pi.nix`.
3. **Slice 2 — new packages, batch A.** Add the four zero-dep new packages (`pi-btw`, `@samfp/pi-memory`, `@benvargas/pi-openai-fast`, `@benvargas/pi-openai-verbosity`, `@juicesharp/rpiv-advisor`).
4. **Gate 2.** Build, spot-check, apply (`nh darwin switch .`), confirm `~/.pi/agent/settings.json` has the new store paths.
5. **Slice 3 — new packages, batch B.** Add the heavier packages (`taskplane`, `@plannotator/pi-extension`, `@gotgenes/pi-permission-system`, `@benvargas/pi-claude-code-use`, `@firstpick/pi-extension-reverse-last`).
6. **Slice 3 — remove confirm-destructive.** Same commit as permission-system.
7. **Gate 3.** Build, spot-check, apply, smoke test by launching pi (`pi --version` and inspecting status line for `openspec:` entry once Slice 4 lands).
8. **Slice 4 — openspec-status.ts extension.** Source the TS file under `modules/`, wire its install via `home.file`.
9. **Gate 4.** Build, spot-check, apply, confirm the status line shows `openspec: <change>` or `openspec: idle`.
10. **Slice 5 — update-pi.sh script.** Add maintenance script and confirm it reports zero drift on its first run.

**Kill switch:** `nix profile rollback` reverts the live system. For a single problematic package, comment out its entry in `pi.nix` and re-apply.

**Feature flag / config toggle:** none needed at the dotfiles level. Pi's own settings.json `packages` array IS the toggle — removing a path disables the package.

## Risks / Trade-offs

- **[Risk]** A new package's peer-dep mismatch (`@mariozechner/*` peer vs `@earendil-works/*` runtime) causes a runtime import failure. **Mitigation:** the schema's progressive-rollout rule means each slice is verified separately. If a package breaks pi at load time, it's narrowly attributable. The build itself can't catch this since pi loads via local paths.

- **[Risk]** `@gotgenes/pi-permission-system` is more aggressive than `confirm-destructive` and blocks operations the user expects to be free. **Mitigation:** the package supports per-rule overrides via its `config.json`. First-run experience may require interactive tuning. Flagged in tasks.md as a human-verification checkpoint.

- **[Risk]** `taskplane`'s git-worktree model overlaps semantically with `seshy`'s tmux-session model. **Mitigation:** document the boundary in AGENTS.md follow-up — `seshy` for human-attachable sessions, `taskplane` for agent-spawned worktrees. Both can coexist without conflict.

- **[Risk]** The openspec-status extension shells out to `openspec list --json` on every render. **Mitigation:** spec requires a 5-second cache TTL and 2-second timeout. If even that proves too chatty, fall back to event-bus-triggered refresh only.

- **[Risk]** Pi-mono rename to earendil-works/pi may revert (unlikely but possible). **Mitigation:** GitHub auto-redirects from the old URL so the fetcher would still work in practice; the rename is captured in the rev pin which doesn't care about repo name.

- **[Trade-off]** Ten new packages add ~6MB to the Nix store closure (estimated from package sizes). Worth it for the functionality.

## Migration Plan

1. **Verify:** `nix flake check` passes on the current main. `~/.pi/agent/settings.json` is captured (so we have a rollback reference if needed).
2. **Apply:** in scoped commits per phase. Each phase ends with `nh darwin switch .` and a manual smoke test of pi.
3. **Confirm:** after each `nh darwin switch`, check `~/.pi/agent/settings.json` `packages` array has the expected store paths, then launch pi and verify the affected extension loads (e.g., `/btw` works after adding pi-btw).

**Rollback:** `nix profile rollback` reverts at the system level. Per-package rollback: comment the entry in `pi.nix`, re-apply.

## Open Questions

- Should the openspec-status extension cache its result in `~/.cache/pi-openspec-status.json` to survive pi restarts, or is in-memory caching sufficient? In-memory is the simpler default; revisit if the agent reports stale data after restarts.
- For permission-system: should we ship an initial `config.json` with our Tier A read-only Bash allowlist mirrored on the pi side, or let the user configure interactively on first run? Leaning toward mirroring the allowlist — defer the decision to implementation; not blocking.
- Whether to also write a tiny `hack/check-pi-extensions.sh` that diffs `pi --list-extensions` (if that command exists) against the package list in `pi.nix`. Useful but not in this change's scope.
