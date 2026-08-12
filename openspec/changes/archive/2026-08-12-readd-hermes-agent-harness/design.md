> The keywords MUST, MUST NOT, SHOULD, SHOULD NOT, and MAY in this document are
> to be interpreted as described in [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119).

## Context

The harness layer is registry-driven. `modules/home/programs/llm/harnesses/registry.nix`
holds one entry per harness, and four consumers read it:

```
harnesses/registry.nix
  │
  ├── harnesses/default.nix        imports h.module
  ├── modules/home/packages.nix    installs pkgs.${h.package}
  ├── runtime/default.nix          h.label, h.ownIcon, h.bridge
  └── lib/instructions.nix         h.context, h.skillLoader
```

This change adds one entry and one module. It introduces no new pattern in that
layer.

Three files deleted by `3dd95d8e8` come back, and two of them come back
differently:

- `overlays/hermes-agent.nix` returns with one changed line: the base package.
- `lib/mcp.nix` regains `formatForHermes`, unchanged. It sits beside the nine
  existing `formatFor*` functions.
- The hermes skill renderer does NOT return. `skills/render.nix` is untouched;
  the skills reach hermes through `skills.external_dirs` instead. See the
  decision below.
- `config/hermes.nix` does NOT return. Its bespoke `yq` activation script is
  replaced by `sysinit.llm.managedFiles`, whose `format` option already accepts
  `yaml` (`modules/home/programs/llm/options.nix`). The closest existing
  example of a harness whose config is one managed YAML-shaped file is
  `harnesses/goose.nix`.

The constraint that decides most of this design: the flake exposes no `checks`
output. `nix build .#darwinConfigurations.lv426.system` and
`nix build .#nixosConfigurations.arrakis.config.system.build.toplevel` are the
only eval gates, so every assertion this change adds MUST be an evaluation-time
`throw` in a module path both configurations reach.

## Goals / Non-Goals

Goals:

- The `hermes`, `hermes-agent`, and `hermes-acp` entrypoints resolve from the
  profile, with no source-built speech stack in the closure.
- The MCP catalog and the skill library reach hermes through the same
  `harnessKit` route every other harness uses.
- A registry entry can no longer name a neovim adapter that does not exist.

Non-Goals:

- Speech input, wake words, or any `voice`/`wake` extra.
- An ACP transport from neovim. The adapter drives the CLI.
- Restoring `openspec/specs/hermes-agent-cli/spec.md` as authority. That corpus
  is history; `proposal.md` holds the criteria.

## Decisions

- Decision: consume `inputs.hermes-agent.packages.${system}.minimal`. That
  output is `hermes-agent[all]`, whose membership is nine extras and excludes
  `voice` [cite: hermes-all-extra-membership] [cite: hermes-all-excludes-voice].
  - Alternative rejected: `packages.default`. It is `minimal` plus 20 extras
    including `voice` [cite: hermes-default-is-full-with-voice], and
    `extraDependencyGroups` only adds groups. There is no subtract knob, so
    `default` cannot be reduced to the set this repository wants.
  - Alternative rejected: upstream's `overlays.default`. It is a pure alias for
    `packages.default` [cite: hermes-overlay-is-alias], so it carries the same
    `voice` extra by construction.

- Decision: add `anthropic` to `extraDependencyGroups` on top of `minimal`.
  Upstream keeps provider extras out of `[all]` because `tools/lazy_deps.py`
  installs them at first use [cite: hermes-all-excludes-voice], and a lazy
  install cannot write into a read-only store path. Upstream's own `messaging`
  output exists for exactly this reason, so the pattern is theirs, not ours.
  `anthropic==0.87.0` is a pure-python wheel, so it adds no compiled build.
  - Alternative rejected: bare `minimal`. The Anthropic provider then fails at
    first use on a store-only install, and the failure looks like a hermes bug
    rather than a packaging choice.
  - Alternative rejected: pre-seeding a writable `~/.hermes` venv so lazy
    install works. That puts provider code outside Nix's control and defeats the
    reason for packaging hermes declaratively.

- Decision: pin the `hermes-agent` input's own `nixpkgs` to a revision. Follow
  the `hunk` input's existing form in `flake.nix`:
  `inputs.nixpkgs.url = "github:NixOS/nixpkgs/<rev>"`.
  - Alternative rejected: `inputs.nixpkgs.follows = "nixpkgs"`, which is what
    the deleted `flake.nix` did. It rebuilds the whole uv2nix venv against this
    repository's nixpkgs on every `nixpkgs` bump. The same failure mode is
    already recorded for `mise` in this repository, where an overlay perturbing
    the closure turned a substituted package into a source build.
  - Alternative rejected: leaving the input unpinned on `nixos-unstable`. The
    python resolution is the part upstream tests, and an unpinned nixpkgs moves
    it under us between builds.

- Decision: add no substituter. Upstream ships a `nix-setup` composite action
  naming the `hermes-agent` Cachix cache [cite: hermes-cachix-cache-name] with a
  readable public key [cite: hermes-cachix-public-key], and no workflow in the
  pinned tree uses that action. That absence cannot be quoted, so it carries a
  method instead of a citation: every file under `.github/workflows/` at rev
  `ee4bb75b` was grepped for `nix-setup`, `nix build`, `nix flake`, and
  `cachix`, and none matched.
  - Alternative rejected: add `hermes-agent.cachix.org` to
    `modules/darwin/system.nix` and `modules/nixos/common/default.nix`. A
    substituter is a trust grant. Granting it to a cache no CI feeds buys no
    build time and widens what the machine will accept store paths from.
  - Alternative rejected: push our own builds to `roshbhatia.cachix.org` from
    this repository's CI. That is a reasonable follow-up and is out of scope
    here, because it changes what this repository publishes.

- Decision: re-wrap the three entrypoints with `symlinkJoin` plus
  `makeWrapper`, as the deleted overlay did, so `claude-code`, `codex`,
  `opencode`, `copilot`, `gh`, and `gemini` are on the wrapped `PATH`. The
  entrypoint names come from upstream's `[project.scripts]`
  [cite: hermes-acp-entrypoint].
  - Alternative rejected: `--suffix PATH` instead of `--prefix`. A hermes
    session would then resolve whichever `claude-code` the ambient shell has,
    so the declarative guarantee would hold only in a login shell.
  - Alternative rejected: setting the subagent paths in hermes's own
    `config.yaml`. That moves a build-time fact into owner-mutable state, where
    the next `hermes config set` can drop it silently.

- Decision: own `~/.hermes/config.yaml` through
  `sysinit.llm.managedFiles.hermes` with `format = "yaml"`, and enforce only the
  keys this repository decides. Owner keys merge.
  - Alternative rejected: the deleted `yq eval-all` activation script. It
    duplicates a merge the shared module already performs, and it has no
    `retire` or `enforce` vocabulary, so a key this repository stops declaring
    stays in the owner's file forever.
  - Alternative rejected: `home.file` with `force = true`. It would clobber
    `hermes model` and `hermes config set` output on every activation.

- Decision: reach the skills through `skills.external_dirs`, pointed at
  `~/.claude/skills`, and write no hermes skill renderer. Hermes reads extra
  skill roots from that key [cite: hermes-skills-external-dirs] and treats any
  directory holding a `SKILL.md` as one skill
  [cite: hermes-skill-dir-holds-skill-md], which is the layout
  `skills/render.nix` already writes. A skill needs no hermes-specific
  frontmatter: `platforms` is the only gate, and an absent `platforms` field
  means every platform [cite: hermes-platforms-field-optional].
  - Alternative rejected: the renderer `3dd95d8e8` deleted. It targeted a
    `<category>/<name>/SKILL.md` layout and emitted `version` and
    `metadata.hermes.category`, neither of which the pinned version reads.
    `external_dirs` did not exist when it was written. Restoring it would add a
    fifth rendered copy of the skill tree to maintain against a contract
    upstream has already replaced.
  - Alternative rejected: `home.file` links into `~/.hermes/skills/`. That is
    the directory `hermes skills install` writes, so this repository and the
    harness would both own it. `external_dirs` is read-only to hermes by
    construction, which is the property we want.

- Decision: hold the shared instructions in `~/.hermes/SOUL.md`, delivered as a
  forced `home.file` link the way `.goosehints` is. Hermes loads `SOUL.md` from
  `HERMES_HOME` into every session's system prompt
  [cite: hermes-soul-is-global-context].
  - Alternative rejected: `agent.coding_instructions` in `config.yaml`. It is a
    string field inside the file the owner also edits, so the instructions would
    merge as owner-editable state rather than sit in the store, and the
    `enforce` list would have to reassert a 130-line string on every activation.
  - Alternative rejected: naming `config.yaml` as the registry `context`. The
    registry's `context` is the instructions file a reader should open;
    `config.yaml` is settings, and pointing at it would make the field mean two
    different things across harnesses.

- Decision: assert in `runtime/default.nix` that every registry
  `neovimAdapter` value names an existing file under
  `neovim/config/lua/harness/adapters/`. The field is declared on all 11 current
  entries and no code reads it.
  - Alternative rejected: leaving the field as documentation. A registry entry
    that names a missing adapter fails at runtime inside neovim, where
    `registry.lua` silently skips an adapter whose `require` fails. A silent
    skip is the worst available failure mode.
  - Alternative rejected: generating the lua `ORDER` list from the Nix registry.
    That is the better end state and a larger change: `ORDER` encodes a
    presentation order the registry does not model, so generating it needs an
    order field first.

## Rollout & Gating

Three phases, in order. Each is buildable on its own.

```
Phase 1  package            Phase 2  harness module      Phase 3  editor
  flake input (pinned)        registry entry               adapters/hermes.lua
  overlays/hermes-agent.nix   harnesses/hermes.nix         registry.lua ORDER
  overlays/default.nix        lib/mcp.nix formatter        adapter assertion
                              skills/ hermes renderer
        │                             │                          │
        ▼                             ▼                          ▼
  nix build both configs      nix build both configs      nix build + nvim headless
  requisites grep is clean    rendered config.yaml parses  get_by_name returns
        │                             │                          │
        └─────────────────────────────┴──────────────────────────┘
                                      ▼
                          owner spot-check, then nh darwin switch
```

The gate sequence is this repository's default: edit, `nix flake check`,
`nh darwin build`, owner spot-check, `nh darwin switch`. One deviation applies.
Phase 1 MUST also run `nix-store --query --requisites` over the built
configuration and grep for `torch`, `faster-whisper`, `ctranslate2`, and
`onnxruntime`. `nh darwin build` exits 0 whether or not those paths are in the
closure, so the build alone cannot decide the criterion this whole change
exists for.

The kill switch is the `hermes` registry entry. Deleting it drops the module
import, the `home.packages` entry, the label, and the notify route in one edit.
There is no separate feature flag, and there SHOULD NOT be one: the registry
entry already is the toggle.

`nh darwin switch` runs from the `sysinit.laurel` checkout, never from this
repository, so phase 3's confirmation happens after a push.

## Risks / Trade-offs

- [The from-source build is slow and upstream calls the Nix path best-effort
  [cite: hermes-nix-path-best-effort]] → Phase 1 is its own phase precisely so
  the cost is measured before any module depends on it. If the build fails or
  takes longer than the owner will accept, the change stops after phase 1 with
  nothing else to revert. This maps to the owner confirmation in `tasks.md`.
- [A second `nixpkgs` enters `flake.lock`] → Accepted. The disk cost is real and
  the alternative is a venv rebuilt against a nixpkgs upstream never tested.
- [`minimal` could gain `voice` in a future upstream release] → The requisites
  grep in phase 1 is a permanent check, not a one-time one. It MUST be re-run
  after any `nix flake update hermes-agent`.
- [The `anthropic` extra makes our derivation differ from any output upstream
  builds] → Accepted with no mitigation, because no upstream output is cached
  anyway. If this repository later publishes to `roshbhatia.cachix.org`, this
  derivation is one of the paths worth pushing.
- [The new adapter assertion could break an unrelated build] → It reads only
  registry values and file existence. The proof is the injected bad value in the
  `Behavior` criteria, which MUST fail, and the unmodified tree, which MUST pass.

## Migration Plan

There is no migration. Nothing currently reads `~/.hermes`, and no other
harness's state is touched.

Deployment, in order, with each impactful step preceded by a verification and
followed by a confirmation:

1. Add the flake input and the overlay. Verify with
   `nix build .#darwinConfigurations.lv426.system` and the requisites grep.
2. Confirm: the owner accepts the measured build time and the closure size
   delta reported by `nix store diff-closures`.
3. Add the registry entry, the module, the MCP formatter, and the skill
   renderer. Verify with both configuration builds.
4. Add the neovim adapter and the assertion. Verify with both builds, the
   injected-bad-value build failing, and the headless neovim check.
5. `git push`, then `nh darwin switch` from the `sysinit.laurel` checkout, gated
   on the two builds exiting 0.
6. Confirm: the owner runs `hermes` once and checks that the keys in
   `~/.hermes/config.yaml` are the ones they meant to declare.

Rollback is `git revert` of the phase commit plus a `nh darwin switch`. No state
outside the store is written, so no rollback step has to undo anything.

## Open Questions

- Whether `hermes` should carry `ownIcon = true`. `hack/update-agent-icons.sh`
  exists, and the answer depends on whether upstream ships a usable SVG.
- Whether `notify = "scrape"` is right. Hermes has hooks, so a bridge extension
  like pi's and opencode's MAY be better. Scrape is the safe default because it
  needs nothing from the harness.

Settled during implementation:

- The nixpkgs revision to pin. `0954f7ee2f6bb3dc7d4e3d0d8bcb8fd4bde4cfc5`, read
  from upstream's own `flake.lock` after the input was added.
- Whether the deleted renderer's frontmatter contract still matches upstream. It
  does not, and the question is now moot: the renderer is not restored. See the
  `external_dirs` decision above.
