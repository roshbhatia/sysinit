> The keywords MUST, MUST NOT, SHOULD, SHOULD NOT, and MAY in this document are
> to be interpreted as described in [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119).

## Context

Three files define the pi harness, and each has a counterpart here:

- `overlays/pi-coding-agent.nix` unpacks a per-platform release tarball chosen
  from `nvfetcherSources` and symlinks one binary. Atomic ships the same asset
  shape [cite: atomic-platform-release-tarballs], so the atomic overlay is the
  same file with different names.
- `modules/home/programs/llm/harnesses/pi/default.nix` is 500 lines. Most of it
  is the npm package set, its fetch and build helpers, and five evaluation-time
  assertions over that set.
- `modules/home/programs/neovim/config/lua/harness/adapters/pi.lua` builds
  `pi --mode rpc --no-session` and hands the command to `pablopunk/pi.nvim`.
  Atomic takes the same flags [cite: atomic-rpc-mode-flag].

Atomic is a pi fork that still reads pi's `piConfig` manifest key and defaults
its config directory to `.atomic` [cite: atomic-reads-pi-manifest-key]. That
compatibility is what makes the parallel cheap and is also what makes the naive
version fail.

The failure is documented upstream. Atomic bundles forks of four pi packages as
always-on builtins, `@bastani/subagents` among them
[cite: atomic-bundled-builtin-packages]. Their comment records the exact
consequence of a second copy arriving by path identity instead of npm-name
identity: dedup is bypassed and the loader raises
`Tool "subagent" conflicts with ...` [cite: atomic-local-path-tool-conflict].
`harnesses/pi/default.nix` installs every pi package as an absolute
`/nix/store` path, which is that path identity.

```
harnesses/pi  packages = [ /nix/store/…-pi-subagents  … ]   ← path identity
                                    │
                                    ▼  dedup keys on npm name, not path
atomic loader ──► @bastani/subagents (builtin, always on)
                  + /nix/store/…-pi-subagents
                  ══► Tool "subagent" conflicts with …   load fails
```

The tool sets also diverged. Atomic's core is `read`, `bash`, `edit`, `write`,
`find`, `search`, `ls`, `ask_user_question`, `todo`
[cite: atomic-core-tool-names]. Pi's is `read`, `bash`, `edit`, `write`, `grep`,
`find`, `ls` [cite: pi-core-tool-names]. Two consequences: `pi-ask-user` is
redundant under atomic, and pi's `pi-tool-display` config, which overrides a
tool named `grep`, names a tool atomic does not have.

Same constraint as the sibling change: the flake exposes no `checks` output, so
every assertion MUST be an evaluation-time `throw` reached by both
configuration builds.

## Goals / Non-Goals

Goals:

- `atomic` resolves from the profile on all three supported systems.
- Atomic starts with no tool-registry conflict, and the conflict is made
  unrepresentable by an assertion rather than avoided by careful editing.
- Pi's rendered `settings.json` is byte-identical before and after the shared
  extraction.
- One derivation provides the external editor both harnesses use.

Non-Goals:

- Declaring atomic workflows from Nix.
- Vendoring atomic's example extensions.
- A stylix theme for atomic.
- Any change to pi's own package list, order, or settings values.

## Decisions

- Decision: package atomic from its per-platform release tarballs through four
  `nvfetcher.toml` entries, exactly as `pi-coding-agent` is packaged.
  - Alternative rejected: `buildNpmPackage` over `@bastani/atomic` from the npm
    registry. Its dependency set includes `embedded-postgres`, a photon wasm
    blob, and `mupdf`, so a from-source build is far more brittle than the
    prebuilt binary upstream tests, and it would need a new `npmDepsHash` on
    every alpha.
  - Alternative rejected: one nvfetcher entry and a runtime platform switch. The
    existing pi overlay throws on an unsupported system, and matching it keeps
    one failure mode across both harnesses.

- Decision: extract pi's npm package set and its fetch and build helpers into
  `harnesses/shared/pi-packages.nix`. Both `harnesses/pi/` and
  `harnesses/atomic/` read that attribute set.
  - Alternative rejected: duplicate the list in the atomic module. There are 19
    packages with pinned versions and hashes, `hack/update-pi.sh` maintains one
    copy, and a second copy drifts on the first bump.
  - Alternative rejected: give atomic no pi packages at all. That drops
    `@gotgenes/pi-permission-system`, which is how this repository applies its
    destructive-command allowlist to pi. A harness with no permission gate is a
    worse outcome than the collision this change exists to solve.

- Decision: the atomic module declares an exclusion set as data, one entry per
  excluded npm name with its reason, and an assertion that throws when an
  excluded name still appears in the rendered `packages` list. Excluded on
  delivery: `pi-subagents` and `pi-web-access`, because atomic bundles forks of
  both [cite: atomic-bundled-builtin-packages]; and `pi-ask-user`, because
  `ask_user_question` is in atomic's core [cite: atomic-core-tool-names] and not
  in pi's [cite: pi-core-tool-names].
  - Alternative rejected: rely on atomic's own dedup. Upstream states dedup is
    keyed on npm package name and that a path identity bypasses it
    [cite: atomic-local-path-tool-conflict]. Store paths are path identities, so
    dedup structurally cannot help here.
  - Alternative rejected: suppress the duplicate tools at runtime with atomic's
    `excludedTools`. That filters a tool after both packages load, and the
    failure is at load time. It would also hide the duplication from the build.
  - Alternative rejected: an allowlist naming the packages atomic DOES get. An
    allowlist silently drops a package added to the shared set, so a future
    `hack/update-pi.sh` bump reaches pi and not atomic with no signal.

- Decision: atomic declares its own `contextHookOrder`. Pi's module asserts that
  the declared hook order matches the load order of the installed set. Removing
  `pi-subagents` from atomic's list means pi's declared order cannot be reused,
  and reusing it would throw on the missing entry.
  - Alternative rejected: share one order list across both harnesses. The
    assertion's whole value is that it compares a declaration against one
    specific installed list, so one list for two different sets is not an
    assertion at all.
  - Alternative rejected: drop the order assertion for atomic. Compaction and
    delegation hooks are order-sensitive, and atomic keeps `pi-vcc` and
    `pi-context`, so the property still matters there.

- Decision: key atomic's `pi-tool-display` config on `search`, and assert that
  every override key is a member of atomic's core tool set.
  - Alternative rejected: copy pi's config with `grep` in it. The key would be
    inert, the display override would silently not apply, and nothing would say
    so. A dead config key that looks live is the failure this repository's other
    assertions exist to prevent.

- Decision: extract `nvimPi` from `harnesses/pi/default.nix` into
  `harnesses/shared/nvim-markdown-editor.nix`, and have both harnesses point
  `externalEditor` at it.
  - Alternative rejected: a second `writeShellScriptBin "nvim-pi"` in the atomic
    module. Two derivations installing the same `bin/nvim-pi` collide in the
    profile, and `nh darwin build` fails.
  - Alternative rejected: name atomic's copy `nvim-atomic`. It avoids the
    collision and leaves two wrappers around one behaviour, which is the thing
    the shared file removes.
  - Alternative rejected: leave `externalEditor` unset for atomic and let
    `$VISUAL` decide. It works and it diverges from pi for no stated reason.

- Decision: the atomic module declares `ATOMIC_SKIP_VERSION_CHECK`. Atomic
  honors `PI_*` names as legacy aliases for its own `ATOMIC_*` variables, and
  the alias is read directly from `process.env`
  [cite: atomic-honors-pi-env-aliases].
  - Alternative rejected: rely on the existing `PI_SKIP_VERSION_CHECK` session
    variable, which atomic would also honor. It works today and makes atomic's
    behaviour depend on a variable pi's module owns, so removing it from pi
    silently changes atomic.
  - Alternative rejected: unset `PI_*` variables globally and set only
    `ATOMIC_*`. Pi needs its own, so this would break pi to tidy atomic.

## Rollout & Gating

Three phases. Phase 1 is a refactor whose success criterion is that nothing
changes, and it MUST land before either later phase.

```
Phase 1  shared extraction        Phase 2  package            Phase 3  harness
  harnesses/shared/                 nvfetcher.toml (x4)         registry entry
    pi-packages.nix                 _sources/generated.nix      harnesses/atomic/
    nvim-markdown-editor.nix        overlays/atomic-*.nix         exclusion set
  harnesses/pi/default.nix          overlays/default.nix          + assertions
    reads the shared files                                      adapters/atomic.lua
                                                                registry.lua ORDER
        │                                   │                          │
        ▼                                   ▼                          ▼
  pi settings.json is             command -v atomic resolves   atomic -p exits 0,
  byte-identical; nh              on all three systems         stderr has no
  darwin build exits 0                                         "conflicts with"
        │                                   │                          │
        └───────────────────────────────────┴──────────────────────────┘
                                            ▼
                              owner spot-check, then nh darwin switch
```

The gate sequence is this repository's default: edit, `nix flake check`,
`nh darwin build`, owner spot-check, `nh darwin switch`. Two deviations apply.

Phase 1 MUST additionally compare pi's rendered settings before and after. The
build exits 0 either way, so only a byte comparison of the rendered
`.pi/agent/settings.json` can decide that the refactor changed nothing. Capture
it with `nix eval` on the managed-file content, or by building both revisions
and diffing the store paths.

Phase 3's conflict criterion cannot be decided by a build at all. A
tool-registry conflict happens when atomic loads, so it needs one real
invocation: `atomic -p 'reply with ok'` after the switch. This is the only
criterion in the change that a command can decide but only after activation,
and `tasks.md` MUST place it after the switch rather than before it.

The kill switch is the `atomic` registry entry. Deleting it drops the module,
the package, the label, and the notify route. Phase 1 survives that deletion by
design, because pi reads the shared files whether atomic exists or not.

## Risks / Trade-offs

- [The phase 1 refactor changes pi's behaviour] → The byte comparison of pi's
  rendered settings is the check, and it maps to the owner confirmation in
  `tasks.md`. Pi is the harness in daily use, so this is the highest-cost
  failure in the change.
- [Atomic releases fast, including alpha tags every few days] → `nvfetcher`
  tracking the wrong channel would pull a prerelease. The open question below
  names the command that decides which tag it resolves. This MUST be settled in
  phase 2, not after.
- [Atomic's builtin forks diverge from the pi packages they replace] →
  `@bastani/subagents` is an adaptation, not a copy, so atomic's delegation
  behaviour will differ from pi's. Accepted: that is the point of running both.
- [The exclusion set is incomplete] → Only three names are excluded on delivery,
  and the remaining 16 are asserted clean by observation rather than by proof.
  The mitigation is the load-time criterion: a conflict from any of the 16 shows
  up as a `conflicts with` string on the first invocation, and the fix is one
  more entry in a list.
- [Two harnesses share the `PI_*` env namespace
  [cite: atomic-honors-pi-env-aliases]] → Mitigated for the one variable this
  repository sets. Not mitigated in general: no assertion checks that a future
  `PI_*` session variable is safe for both. Stated rather than solved.

## Migration Plan

Nothing migrates. Pi's state under `~/.pi` is untouched, and atomic writes only
under `~/.atomic`.

Deployment, in order, with each impactful step preceded by a verification and
followed by a confirmation:

1. Extract the shared files and repoint pi's module. Verify with
   `nh darwin build` exiting 0 and pi's rendered `settings.json` comparing
   byte-identical to the pre-change revision.
2. Confirm: the owner accepts that pi's settings are unchanged and that the
   shared split lands where they want it.
3. Add the nvfetcher entries, run `nvfetcher`, and add the overlay. Verify with
   `nix build` on all three systems and by checking which tag was resolved.
4. Add the registry entry, the atomic module with its assertions, and the neovim
   adapter. Verify with both configuration builds, plus two injected-defect
   builds that MUST fail: an excluded package returned to the list, and a
   tool-display key set to `grep`.
5. `git push`, then `nh darwin switch` from the `sysinit.laurel` checkout, gated
   on `nix flake check` and `nh darwin build` exiting 0.
6. Verify after the switch: `atomic -p 'reply with ok'` exits 0 with no
   `conflicts with` on stderr, `pi -p 'reply with ok'` still exits 0, and
   `find ~/.pi -newermt '-5 minutes'` returns nothing after the atomic run.
7. Confirm: the owner decides whether running two pi-lineage harnesses side by
   side is worth keeping.

Rollback is `git revert` of the phase commit plus a `nh darwin switch`. Reverting
phase 3 alone leaves the shared extraction in place, which is inert.

## Open Questions

- Which tag `nvfetcher` resolves for `bastani-inc/atomic`. The repository has
  both `0.9.12` and `0.9.13-alpha.1`, and the answer decides whether a filter is
  needed. Settled by running `nvfetcher` once and reading the resolved version in
  `_sources/generated.nix`.
- Whether `pablopunk/pi.nvim` hardcodes the `pi` binary anywhere its `cmd`
  option does not cover. `adapters/pi.lua` passes `cmd` into `pi.run`, so the
  spawn is parameterised, and nothing yet proves the plugin's other paths are.
  Settled by reading the plugin source before writing `adapters/atomic.lua`.
- Whether atomic reads extension config from `.atomic/agent/extensions/<name>/config.json`,
  mirroring pi. The permission-system config depends on it, and a wrong path is
  a silently ungated harness rather than a build failure.
- Whether atomic's theme schema still accepts pi's theme JSON. Deferred to a
  non-goal, and worth knowing before someone assumes it.
- Whether the notify bridge extension pi uses loads unchanged under atomic.
  Atomic reads the `pi.extensions` manifest key [cite: atomic-reads-pi-manifest-key],
  which suggests yes, and the registry entry claims `notify = "hook"` on that
  basis.
