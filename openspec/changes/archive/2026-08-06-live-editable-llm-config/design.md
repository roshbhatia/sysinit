## Context

`modules/home/programs/llm/` is 7,147 lines of Nix across 47 files and absorbs
23% of this repository's commit volume (186 of 818 commits in the last three
months). Two distinct forces drive that churn, and the module currently applies
one mechanism to both.

Measured facts that set the design:

- `config/claude.nix` carries 13 store-path interpolations. Hook commands,
  guard scripts, and binary paths genuinely need Nix evaluation.
- All 17 skill bodies and `lib/instructions.nix` carry zero. The one skill that
  takes `{ pkgs, lib }` uses them only to `fetchurl` a pinned upstream file.
- 16 `''${` escapes exist across 5 skill bodies purely to survive a Nix string.
- 36 `force = true` entries and 14 plain store-symlink harness config targets.
- 5 harnesses already carry a bespoke activation script: `goose.nix` (yq),
  `opencode.nix` (jq plus schema validation), `pi.nix` (jq), `codex.nix`
  (symlink-to-copy), and `claude.nix` (jq patch).

Patterns this design extends rather than invents:

- `config/notify.nix` builds six shell tools with `pkgs.writeShellApplication`
  and installs them through `home.packages`. Both new scripts follow it.
- `config/opencode.nix:100` writes a merged file to a temp path, validates it
  against a schema, then moves it into place. `lib/managed-file.nix`
  generalises exactly that sequence.
- `config/opencode-render.nix:39` already renders one jq merge program used by
  both the activation script and the flake check, so the two cannot drift. The
  helper keeps that property.
- `lib/harness-kit.nix` is the precedent for collapsing a block every harness
  repeats into one call.

The current merge is two-way. It has no base, so it cannot express deletion.
The repository already documents the consequence, in
`openspec/changes/modernize-opencode-and-pi-config/design.md:220`: "A key the
phase added and the revert undeclares also needs an entry in the retired-key
list, because a deep merge cannot remove a key on its own." The hand-written
`retired`, `authoritative`, and `ownerPreference` lists are a manual
field-ownership manifest standing in for that missing base.

## Goals / Non-Goals

Goals:

- A harness can write its own config file without failing.
- A setting changed from inside a harness survives, and can be turned into Nix
  source with one command.
- Deletion works without a hand-written tombstone list.
- Editing a skill body takes effect without a rebuild.
- One merge implementation instead of five.

Non-Goals:

- Moving `lib/instructions.nix` out of Nix evaluation.
- Editing any skill prose or any setting value.
- Per-host divergence of skills or settings.
- Replacing Home Manager's file linking for anything that is not contested.

## Decisions

- Decision: skill source becomes `skills/<name>/SKILL.md` with flat YAML
  frontmatter, and the whole skill is a directory so helper scripts and
  reference documents sit beside the body.
  - Alternative rejected: keep the Nix attrset registry and change only how it
    is installed. The fast loop requires a renderer that runs without
    `nix eval`, and a renderer cannot read a Nix attrset. This alternative
    cannot deliver the primary goal at all.

- Decision: frontmatter in `SKILL.md` is the single source for skill metadata.
  Nix reads it with a small `lib/frontmatter.nix` that handles flat
  `key: value` pairs only. The renderer reads the same bytes with `yq-go`.
  - Alternative rejected: keep a thin `skills/registry.nix` for metadata and
    move only the bodies. That splits one skill across two files and two
    languages, and the renderer still cannot read the Nix half without an
    evaluation step, which reintroduces the latency this change removes.

- Decision: the renderer writes to `$XDG_STATE_HOME/sysinit/llm/skills/`, and
  each skill is installed as a per-skill out-of-store directory symlink.
  - Alternative rejected: one whole-directory symlink for
    `~/.claude/skills`. That root also holds vendored skills from
    `inputs.specutil` and `inputs.ast-grep-skills`, which must stay
    Nix-managed. A whole-directory link forces the renderer to own and place
    store paths it has no way to resolve.

- Decision: the source keeps the `{{agent}}` placeholders, and every harness
  tree including Claude's is a render.
  - Alternative rejected: write `teammate` literally in the source and
    reverse-substitute to `subagent` for the other harnesses. That makes the
    Claude path zero-step, but the reverse rewrite is a lossy many-to-one
    substitution over prose. Any sentence that legitimately says "teammate"
    about a person would be silently rewritten.

- Decision: the renderer runs both at activation and as a standalone command,
  and a flake check asserts the two produce identical bytes.
  - Alternative rejected: a file watcher or a direnv hook. That adds a
    background process and a silent failure mode. An explicit command is
    debuggable and matches the `hack/*.sh` convention already in the
    repository.

- Decision: `lib/managed-file.nix` records the applied content as a sidecar
  base file next to each target, and reconciles with a three-way merge.
  - Alternative rejected: keep the two-way deep merge and keep maintaining the
    `retired` lists. The lists are already documented as a rollback hazard,
    and they must be updated by hand on every undeclaration, which is the
    failure mode rather than a mitigation.

- Decision: a three-way conflict fails activation and leaves the file
  untouched.
  - Alternative rejected: let Nix win on conflict, which is the current
    two-way behaviour. Silently discarding a setting the owner changed inside
    a harness is the exact loss this change exists to prevent.

- Decision: `sysinit-llm-capture` prints a Nix attrset to stdout and never
  writes under `modules/`.
  - Alternative rejected: auto-patch the harness module. Those files carry
    hand-written comments and evaluation-time assertions, so a generated edit
    is unreviewable, and the repository rule is to stage and propose rather
    than mutate.

- Decision: phase 1 is the managed-file work and phase 2 is the prose move.
  - Alternative rejected: prose first. The writability failure is active and
    already blocks the owner mid-session. The prose latency is chronic but
    never blocking, so it ships second.

## Rollout & Gating

Phase 1 ships first, alone.

1. Add `lib/managed-file.nix` and convert the 5 harnesses that already have a
   bespoke script. Gate: `nix flake check` green, `nh darwin build` green, and
   the owner reviews the diff of each live target after the switch.
2. Convert the 14 remaining store-symlink targets. Gate: each harness starts
   once and writes a setting from its own interface without error.
3. Delete the `retired`, `authoritative`, and `ownerPreference` lists. Gate:
   an undeclaration test removes one key from Nix, switches, and confirms the
   key leaves the live file with no list entry.

Phase 2 ships after phase 1 is confirmed.

4. Move the 17 skill bodies and add the renderer. Gate: the rendered tree is
   byte-identical to the tree the current Nix path produces, asserted by a
   flake check before any switch.
5. Switch the install to per-skill out-of-store symlinks. Gate: the owner
   edits one skill, runs the renderer, and confirms the harness serves the
   edit with no switch.

Default gate sequence for every step: edit, `nix flake check`, `nh darwin
build`, owner spot-check, `nh darwin switch`. No deviation.

Kill switches, in increasing blast radius:

- Per file: set `enable = false` on one managed file. That target reverts to
  its previous handling and nothing else changes.
- Per phase: revert the phase commit and run `nh darwin switch`. For phase 1,
  also delete the sidecar base files, because a stale base seeds a wrong merge.
- Phase 2 needs no state cleanup. The state directory is regenerated and holds
  no owner data.

## Risks / Trade-offs

- [The first switch seeds a wrong base from a live file that already drifted]
  -> Before phase 1 step 1, copy every target file to `.sysinit/` and have the
  owner review each captured file. This is the explicit human-verification
  checkpoint in tasks 1.1 and 1.2.

- [Two frontmatter parsers, one in Nix and one in the renderer, disagree]
  -> The Nix reader accepts flat `key: value` only, and a flake check rejects
  any skill whose frontmatter is nested or unclosed. The accepted grammar is
  small enough that both parsers implement the same thing.

- [Moving 2,113 lines of prose loses or corrupts content] -> The move is
  gated on a byte-identity check against the current Nix render before any
  switch, which is the same technique `harness-kit`'s "Byte-identity preserved
  during refactor" requirement already uses in this repository.

- [Deleting the retired lists lets stale keys return] -> Phase 1 step 3 is
  gated on an explicit undeclaration test, not on inspection.

- [A body edit reaches the harness with no review, because the tree is live]
  -> This is the point of the change and is accepted. The mitigation is that
  the source stays in git, so `git status` reports drift, and the pre-commit
  path is unchanged.

- [`nh darwin build` no longer proves the skill tree, because the renderer
  runs at activation] -> The flake check renders the tree in a sandbox and
  compares it, so build-time coverage is preserved by a different mechanism.

## Migration Plan

Phase 1:

1. Verify: capture all 23 target files to `.sysinit/llm-capture-pre/` and have
   the owner review them. Confirm which of the 14 symlink candidates the
   harness writes at runtime.
2. Verify: `nix flake check` and `nh darwin build` green; review `git diff`.
3. Apply: `nh darwin switch`. This converts symlinks to real files and seeds
   each sidecar base.
4. Confirm: every target is a regular file, every sidecar base exists and
   parses, and each harness starts once and saves a setting.
5. Verify: remove one key from Nix and run `nh darwin build`.
6. Apply: `nh darwin switch`.
7. Confirm: the key is gone from the live file and no list entry was needed.

Rollback for phase 1: revert the commit, delete the sidecar base files, run
`nh darwin switch`, then restore from `.sysinit/llm-capture-pre/`. Restoring
the files alone does not work, because activation re-imposes the reverted
shape on any later switch for an unrelated reason.

Phase 2:

8. Verify: the byte-identity flake check passes for all four rendered trees.
9. Verify: `nh darwin build` green; review `git diff`.
10. Apply: `nh darwin switch`.
11. Confirm: every skill resolves through its symlink, the vendored skills are
    still store symlinks, and one edited skill reaches the harness after a
    renderer run with no switch.

Rollback for phase 2: revert the commit and run `nh darwin switch`. The state
directory holds no owner data and needs no restore.

## Adversarial Review

Rubric: the spec scenarios in all three spec files including every scenario
marked `- **POLARITY** negative`, the Decisions above with their rejected
alternatives, the gates in Rollout & Gating, and the Non-goals in
`proposal.md`.

The deterministic `specutil check` lint is mandatory and runs on every phase.
The LLM critic loop is default-on and owner-gated: the `adversarial-review`
skill elicits approve or deny, and the owner may waive it for a small phase,
recorded as `Adversarial review: waived by owner`. This change spans two
capabilities and mutates live system state, so the round cap is K=6 when the
loop runs. A cap hit is reported as open objections, never as a pass. Under
Claude Code the critics are in-process teammates. Methodology lives in the
`adversarial-review` skill and is not restated here.

## Open Questions

- The existing `agent-skill-library` requirement "Required global skills are
  installed by default" lists `openspec-propose`, `openspec-apply`,
  `openspec-explore`, and `openspec-archive`. `skills.nix:11` has not required
  those for some time. The delta spec aligns the requirement with the code.
  Confirm that is the intent rather than a regression to restore.
- Does any harness read its skill root before the activation renderer runs on
  a fresh machine? If one does, the first launch after a clean install sees an
  empty tree until the renderer completes. A seed-at-eval fallback would fix
  it and costs the byte-identity guarantee, so it is deferred until observed.
- Should `sysinit-llm-capture` cover `~/.claude.json`? It is the largest live
  file, it holds session state, and only one key in it is Nix-declared.
