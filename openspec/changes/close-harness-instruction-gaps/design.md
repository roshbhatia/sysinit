## Context

`modules/home/programs/llm/lib/instructions.nix` renders one text and every
harness config pulls it through `harness-kit.nix`. Seven harnesses already do
this: claude, codex, gemini, opencode, amp, crush, and devin. The pattern is
one line in the harness's config, for example `config/amp.nix:44`.

Four harnesses do not.

- `config/cursor.nix` writes three MDC rule files instead. The body of
  `config/cursor-rules/always.mdc` is authored prose that summarizes the
  generator's output, and it has drifted from it.
- `config/goose.nix` sets `CONTEXT_FILE_NAMES` so goose knows which filenames
  to read, but nothing writes a file at a global path.
- `config/copilot-cli.nix` writes a settings file and an MCP file only.
- `config/pi.nix` writes settings, keybindings, a theme, and extensions. Pi
  reads `~/.pi/agent/AGENTS.md` per its bundled `docs/usage.md`, and nothing
  writes it.

Pi's skill situation is the same shape. Pi's bundled `docs/skills.md` documents
a `skills` array in `~/.pi/agent/settings.json` and gives
`["~/.claude/skills"]` as the worked example for reusing another harness's
tree. That array is unset.

Patterns reused: the `home.file` and `xdg.configFile` entries in
`config/devin.nix:82` are the shape for each new context file. The
`validateMdc` build assertion at `config/cursor.nix:43`, consumed at
`config/cursor.nix:58`, is the shape for the new coverage assertion.

No new pattern is introduced.

## Goals / Non-Goals

Goals:

- Four more harnesses read the same conventions and prohibitions.
- One place declares coverage, so the next harness cannot be added silently
  without it.
- Cursor's always-applied rule stops being a second source of truth.
- Pi can load the skills its context file points at.

Non-goals:

- Editing the shared instruction text.
- Repairing every stale requirement in the `agent-context-files` spec; only
  the two the coverage requirement contradicts are corrected.
- Any harness setting outside context and skills.
- Adding a harness.

## Decisions

### D1. Coverage is declared in one attribute set, checked at build time

A single attribute set maps each configured harness to either a context path or
an exemption with a reason. `default.nix` already imports every harness config,
so the set is compared against that import list and a mismatch throws.

- Alternative rejected: check coverage in a `nix flake check` derivation.
  Rejected because a missing context file is an evaluation-time fact that a
  `throw` reports at the exact module, while a check reports it later and with
  less location detail.

### D2. Each path is confirmed against the installed build before it is declared

Pi's path is confirmed: its bundled `docs/usage.md` names
`~/.pi/agent/AGENTS.md`. Goose's filename is confirmed: `.goosehints` appears
in the installed `goose-cli` binary and `CONTEXT_FILE_NAMES` is already set.
Copilot's path IS confirmed, contrary to an earlier draft of this design. The
first scan read the wrapper binary at `bin/copilot`; the strings live in the JS
bundle under `lib/github-copilot-cli/`. That bundle names
`$HOME/.copilot/copilot-instructions.md` and
`$HOME/.copilot/instructions/**/*.instructions.md` as user-level instruction
sources, and `~/.copilot/skills/` as a personal skills root.

The lesson generalises: scan the artifact that holds the logic, not the wrapper
that launches it.

An unconfirmed harness is declared exempt with the reason, not pointed at a
guessed path. A guessed path produces a file nothing reads, which looks like
coverage and is not.

- Alternative rejected: write `~/.copilot/AGENTS.md` on the assumption that
  copilot follows the AGENTS.md convention. Rejected because the repository
  already carries a lesson that a harness's flags and paths must be read from
  the binary rather than carried over from a sibling tool.

### D3. Cursor's always rule is generated; its two glob rules stay authored

The always-applied rule is a restatement of the cross-repository context, so it
is generated. The nix and markdown rules are glob-scoped domain rules, which
the shared context deliberately excludes under its global-means-cross-repo
principle. Generating those would either widen the shared context or invent a
second generator.

- Alternative rejected: generate all three rule files from `instructions.nix`.
  Rejected because the shared context holds no Nix-specific or Markdown-specific
  rules, so two of the three would render empty.

### D4. Pi's skills array points at the Claude tree, not a pi-specific copy

Amp and devin each get their own rendered skills tree because their frontmatter
validation rejects keys the Claude render emits. Pi's bundled `docs/skills.md`
states that pi is lenient about frontmatter and explicitly supports pointing at
another harness's tree. So pi reads the Claude tree directly.

- Alternative rejected: render a third skills tree at `~/.pi/agent/skills/`.
  Rejected because it triples the skill file count on disk for a loader that
  the vendor documents as compatible with the existing tree.

## Rollout & Gating

Three phases.

1. The coverage set and its assertion, with every currently covered harness
   declared and the four gaps declared as known-missing. This phase changes no
   rendered file. Gate: `nix flake check` and `nh darwin build` are green, and
   the assertion fires when a harness is removed from the set.
2. Pi and goose context files, plus pi's skills array. Both paths are
   confirmed. Gate: the owner starts one pi session and confirms the context
   loads and `/skill:` completion lists the registry skills.
3. Cursor's generated always rule, and copilot's outcome from a confirmation
   spike. Gate: the owner reads the rendered `always.mdc` and confirms no fact
   is stated twice.

Default sequence: edit, `nix flake check`, `nh darwin build`, owner read of the
rendered file, `nh darwin switch`. No deviation.

Kill switch: each harness's context file is one `home.file` entry, which is a
store symlink, so removing the entry and switching restores that harness's
previous state.

Pi's `skills` array is not a `home.file` entry. It reaches disk through the deep
merge at `config/pi.nix:578`, which never removes a key. Rolling pi back
therefore takes three steps: remove the `home.file` entry, add `skills` to the
retired-key list that `modernize-opencode-and-pi-config` introduces, and switch.
Removing the entry alone leaves pi loading the Claude tree forever.

The coverage assertion is one `throw` that can be relaxed to a warning if it
blocks an unrelated build.

## Risks / Trade-offs

- The rendered context has a 45-line cap enforced at `instructions.nix:140`.
  Four more consumers do not change the text, so the cap is unaffected.
  Mitigation: none needed; recorded so a reviewer does not raise it.
- Correcting the section list and the line cap in `agent-context-files` edits a
  requirement this change did not set out to touch. Mitigation: the correction
  is confined to the one requirement the new coverage requirement would
  contradict, and it states the previous text and why it changed. Flagged for
  owner confirmation in phase 1.
- Cursor's always rule loses hand-written repository facts when its body is
  generated. Mitigation: capture the deleted text before the edit and move any
  fact worth keeping into the repository's own `AGENTS.md`, which is where a
  repository fact belongs. Flagged as a human-verification checkpoint in
  phase 3.
- Pi may warn on skill frontmatter keys the Claude render emits. Mitigation:
  pi's bundled docs state it warns and stays lenient. Phase 2 confirms this on
  a live session before the phase is marked done.
- Goose's global hints path is inferred from the filename in the binary and the
  configured config directory, not from a literal path in the binary.
  Mitigation: phase 2 confirms the load on a live goose session before the
  phase is marked done, and goose is declared exempt if it does not load.

## Migration Plan

1. Verify: `nix flake check` passes before any edit.
2. Apply phase 1. Confirm: removing a harness from the coverage set fails the
   build with that harness named.
3. Verify: `nh darwin build` is green. Apply phase 2 and switch. Confirm: a pi
   session loads the context and lists the registry skills; a goose session
   loads the hints.
4. Verify: the deleted body of `always.mdc` is captured and any surviving fact
   is placed in the repository `AGENTS.md`. Apply phase 3 and switch. Confirm:
   the owner reads the rendered rule file and finds no restated fact.

Rollback: revert the phase's commit and switch. No phase writes state outside
the generated dotfiles, which are replaced on the next activation.

## Adversarial Review

Rubric: the spec scenarios in this change including every negative one, the
Decisions above, the Rollout & Gating phase gates, and the proposal Non-goals.

The deterministic half is mandatory. `specutil check` runs on every phase.

The critic half is default-on and owner-gated. The `adversarial-review` skill
elicits approve or deny; the owner may waive it for a small phase, recorded as
`Adversarial review: waived by owner`. When run, independent critics attempt to
break the phase with a concrete failing scenario that names a violated rubric
item. The author revises against surviving objections. The loop repeats until
no objection survives or K=4 rounds. Under Claude Code the critics are
in-process teammates. See the `adversarial-review` skill for the methodology.

## Open Questions

- The remaining drift in `agent-context-files` is not repaired here. The
  section list, the line cap, and the Stack section are corrected, because the
  new coverage requirement contradicts them. The `nix build .#agents-md` target
  still describes code that does not exist and needs its own change.
- Does copilot read a global instruction file at all? The spike in phase 3
  answers this. If it does not, copilot stays exempt.
- Should the repository's own `AGENTS.md` absorb the cursor facts that are
  worth keeping, or should they be deleted? The owner decides in phase 3.
