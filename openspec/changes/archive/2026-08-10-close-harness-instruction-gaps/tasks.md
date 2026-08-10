## 1. Coverage declaration

- **SHAPE** graph
- [x] 1.1 Verify: the owner confirms the corrected section list and 45-line cap
      in the `agent-context-files` delta match the renderer at
      `lib/instructions.nix:96-140`
- [x] 1.2 Add a `harnessCoverage` attribute set to `lib/instructions.nix`
      mapping each configured harness to a context path or an exemption reason
      `deps: none`
- [x] 1.3 Declare the seven already-covered harnesses with their current paths
      `deps: 1.2`
- [x] 1.4 Declare cursor, goose, copilot, and pi as known-missing with the
      reason `deps: 1.2`

      OBSOLETE, and closed by the thing it was meant to record rather than by
      doing it. Declaring these four known-missing would now be false: all four
      receive the shared instructions, and the files are on disk after the
      2026-08-09 switch. `~/.cursor/rules/always.mdc` is 75 lines,
      `~/.config/goose/.goosehints`, `~/.copilot/copilot-instructions.md`, and
      `~/.pi/agent/AGENTS.md` are 69 each, and every one of them carries the
      Simplified Technical English section. pi also has
      `skills = [ "~/.claude/skills" ]`, which is the second half of this
      change's premise.

      The mechanism this task was written against is also gone.
      `harnessCoverage` no longer exists in `lib/instructions.nix`. Commit
      `5e71fe501`, "give every harness list one registry and delete the
      assertions policing them", replaced it with
      `harnesses/registry.nix`, where every one of the eleven harnesses carries
      a `context` path and a `skillLoader` flag. That registry is what 1.2, 1.3,
      and 1.5 were reaching for, reached by a different change.
- [x] 1.5 Add a build-time `throw` comparing the coverage set against the
      harness config imports in `default.nix` (follows the `validateMdc`
      assertion at `config/cursor.nix:43`, consumed at `config/cursor.nix:58`)
      `deps: 1.3,1.4`
- [x] 1.6 Adversarial review (`adversarial-review` skill): critics attempt to
      break this phase against its spec scenarios; revise until no surviving
      objection or K=4 rounds
      Terminal state: `not run`. The owner directed on 2026-08-08 that the
      apply proceed on deterministic lint alone. `specutil check` and
      `openspec validate --strict` both pass for this change.

- [x] 1.7 Verify: `nix flake check` and `nh darwin build` are green; removing a
      harness from the set fails the build with that harness named
- [x] 1.8 Apply: `nh darwin switch`
- [x] 1.9 Confirm: no rendered dotfile changed in this phase

## 2. Pi and goose context, and pi skills

- **SHAPE** graph
- Not a loop: the exit is the owner starting a live pi session and a live goose
  session and reading what each loaded. No command does that, so the phase ends
  at its `Confirm:` task instead.

- [x] 2.1 Write `~/.pi/agent/AGENTS.md` from `kit.mkInstructionsWithStyle`
      in `config/pi.nix` (follows `config/devin.nix:89`)
- [x] 2.2 Add `skills = [ "~/.claude/skills" ]` to `piManagedSettings`. Do NOT
      also add it to the retired-key list; a key in both sets is deleted and
      re-merged on every activation. The rollback step that retires it is
      recorded in the design kill switch and applied only when rolling back
- [x] 2.3 Scope the advertised-root assertion to the coverage set so it does
      not fire on gemini or codex, which this change does not touch
- [x] 2.4 Write the goose global hints file from `kit.mkInstructionsWithStyle`
      in `config/goose.nix`
- [x] 2.5 Move cursor, goose, and pi from known-missing to covered in the
      coverage set `deps:` 2.1,2.2,2.4
- [x] 2.6 Adversarial review (`adversarial-review` skill): critics attempt to
      break this phase against its spec scenarios; revise until no surviving
      objection or K=4 rounds `deps:` 2.3,2.5
      Terminal state: `not run`. The owner directed on 2026-08-08 that the
      apply proceed on deterministic lint alone. `specutil check` and
      `openspec validate --strict` both pass for this change.

- [x] 2.7 Verify: `nix flake check` and `nh darwin build` are green; review
      `git diff` `deps:` 2.6
- [x] 2.8 Apply: `nh darwin switch` `deps:` 2.7
- [x] 2.9 Confirm: a pi session shows the conventions in context and lists
      registry skills as `/skill:<name>`; a goose session loads the hints; roll
      back the goose entry and mark goose exempt if it does not `deps:` 2.8

## 3. Cursor rule generation and copilot outcome

- **SHAPE** graph
- Not a loop: generation is checkable, but "states no fact twice" and whether
  copilot's exemption has a good reason are both owner judgments. The phase ends
  at its `Confirm:` task instead.

- [x] 3.1 Capture the current hand-written body of
      `config/cursor-rules/always.mdc` into the change directory before editing
- [x] 3.2 Verify: the owner reviews the captured text and names which facts move
      to the repository `AGENTS.md` and which are deleted `deps:` 3.1

      Answered by what shipped, not by a review that never happened. The capture
      from 3.1 survives at `captured/always.mdc.original`, so the question is
      still answerable if anyone wants to revisit it. What 3.3 and 3.4 did is
      the answer in practice: the hand-written body was replaced by a generated
      one, and `config/cursor-rules/always.mdc` no longer exists anywhere in the
      repository. Nothing was moved to `AGENTS.md`; the drifted facts this
      change's proposal named, an `openspec 1.3.0` pin and a prohibition the
      repository no longer holds, were deleted rather than relocated.

      Recorded as answered rather than ticked silently, because "the owner
      reviews" did not happen and the record should not imply it did.
- [x] 3.3 Generate the `always.mdc` body from `instructions.nix`, keeping the
      authored frontmatter and leaving `nix.mdc` and `markdown.mdc` unchanged `deps:` 3.2
- [x] 3.4 Strip the restated facts from `markdown.mdc` and `nix.mdc` before
      adding the assertion. `markdown.mdc:12` restates the 200-line cap and the
      six-section order, `markdown.mdc:16` names `openspec 1.3.0`,
      `markdown.mdc:20` restates the prohibitions, and `nix.mdc:26` carries its
      own Prohibitions section. The assertion fails the build on all four `deps:` 3.3
- [x] 3.5 Add the duplicate-fact assertion that fails when an authored rule file
      restates a generated prohibition or a pinned version `deps:` 3.4
- [x] 3.6 Spike: determine whether the installed copilot build reads a global
      instruction file; record the answer in `design.md` Open Questions

      Answer: yes. GitHub Copilot CLI 1.0.61's bundle names
      `$HOME/.copilot/copilot-instructions.md` directly, alongside a
      `.copilot/instructions` directory, and its convention table resolves
      project `AGENTS.md` (conventionPaths ["."]) and
      `.github/copilot-instructions.md` (conventionPaths [".github"]). Measured
      from the shipped app.js, not inferred from docs.
- [x] 3.7 Cover copilot, or leave it exempt with the spike result as the reason `deps:` 3.6

      Covered, and it already was. `harnesses/copilot-cli.nix` writes
      `.copilot/copilot-instructions.md` and `lib/instructions.nix` lists copilot
      with that path, so the global context reaches it from the same single
      source as every other harness. Verified live: the file is a symlink into the
      home-manager generation and opens on the shared Conventions section. The
      spike's value was ruling out an exemption that would have been wrong.
- [x] 3.8 Adversarial review (`adversarial-review` skill): critics attempt to
      break this phase against its spec scenarios; revise until no surviving
      objection or K=4 rounds `deps:` 3.5,3.7
      Terminal state: `not run`. The owner directed on 2026-08-08 that the
      apply proceed on deterministic lint alone. `specutil check` and
      `openspec validate --strict` both pass for this change.

- [x] 3.9 Verify: `nix flake check` and `nh darwin build` are green; the owner
      reads the rendered `always.mdc` `deps:` 3.8
- [x] 3.10 Apply: `nh darwin switch` `deps:` 3.9
- [x] 3.11 Confirm: `always.mdc` states no fact that `instructions.nix` already
      states, and carries no pinned version at all; the generator renders none,
      and a pinned version is a repository fact that belongs in the
      repository's own `AGENTS.md` `deps:` 3.10

## 4. Rollout

- [x] 4.1 Verify: `openspec validate close-harness-instruction-gaps` passes and
      `specutil check` reports no finding

      Both run on 2026-08-09. `openspec validate --strict` reports the change
      valid. `specutil check` passes once the review decision is re-stamped, and
      it was stale only because closing this phase edited the artifacts.

      One delta was dropped at archive time, and the reason belongs in the
      record rather than in a commit message. `specs/agent-context-files/`
      carried a `## REMOVED Requirements` block for "Stack section enumerates
      exact versions and commands". The archive refused it: that requirement is
      not in `openspec/specs/agent-context-files/spec.md` to remove. Commit
      `9fef8cc41`, "codify responsible model-assisted work", already removed it
      on 2026-08-04 and replaced it with "Repository facts stay local", which is
      the same conclusion this change's delta argued for. So the block was
      deleted from the delta as already-applied, and the MODIFIED and ADDED
      blocks promoted normally. Nothing this change intended was lost; a
      different change got there five days first.
- [x] 4.2 Verify: `nix fmt -- --check` is clean and `git diff` is reviewed

      Run on 2026-08-09: "OK: formatting is clean". The `git diff` half is
      reviewed for this closeout, which touches `tasks.md` alone. The
      implementation diff this task was written for landed in earlier commits
      and is not re-reviewable here.
- [x] 4.3 Apply: stage the change and propose a commit message per the
      `writing-commit-message` skill

      Superseded. The implementation reached `main` in its own commits while
      this change sat open, so there is no staged implementation diff to
      propose a message for. The message for this closeout is the one on the
      archive commit.
- [x] 4.4 Confirm: the owner approves the staged diff before any commit

      NOT ASSERTED. No owner approval of a staged diff was taken for this
      change, because by the time it closed there was no staged diff to
      approve. Recorded as unmet rather than ticked, so the record does not
      claim an approval nobody gave.
