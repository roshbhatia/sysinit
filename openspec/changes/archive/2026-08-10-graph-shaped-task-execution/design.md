> The keywords MUST, MUST NOT, SHOULD, SHOULD NOT, and MAY in this document are
> to be interpreted as described in [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119).

## Context

The schema fork at `modules/home/programs/llm/openspec-schema/schema.yaml`
already carries most of a task-graph model. It declares a phase shape
(`- **SHAPE** loop` or `- **SHAPE** graph`), a per-subtask dependency edge, a
loop iteration bound, a terminal-state vocabulary, a review subtask per phase,
and a human gate placed on irreversible actions. `specutil check` reads the
declared markers and never infers intent from prose.

It also already carries the runner. The apply instruction routes a concurrent
ready set on what the work needs: teammates for shared-repository
implementation, fresh-context subagents for anything adversarial or verifying,
and fresh-context subagents for read-only investigation. None of those opens a
pane, and the same paragraph already says "Give each a disjoint file set and say
so in the prompt".

One fact about the scheduler shapes every rule below. `specutil next` releases a
subtask only when every declared dependency is complete. A ready set therefore
never contains two subtasks with an edge between them. Any rule about a ready
set that keys on the declared edges has an empty extension, and the coupling
that does survive into a ready set is the file two subtasks both write.

What is missing is the part that decides whether an edge should exist at all,
the part that decides whether a ready set is safe to fan out, the part that
names who owns the merge, and the declaration of the file set that the routing
paragraph already asks the orchestrator to hand out.

The design influence is the `graph-engineering` skill by codejunkie99. It is a
pointer and nothing in this document rests on its content: `citelock capture`
could not fetch it, and a claim that cannot be pinned is not written as a claim.
The empirical material and its citations are in the proposal.

Two existing decisions bind this one. `dc32e2697` removed every agent-initiated
route into a terminal or an editor, and demoted `wtrun` to an owner command with
the reason "The defect this removes was never the pane. It was an agent opening
one." `modules/home/programs/zsh/integrations/seshy-wezterm.zsh` creates one zmx
session per seshy session, on demand, through `s`. Both stay.

## Goals / Non-Goals

Goals:
- an edge in a `graph` phase exists only when the downstream task reads the
  upstream task's output
- a ready set whose declared write sets overlap runs in one context
- every `graph` phase names the one node that owns the merge
- the file set the routing paragraph hands each worker is declared in `tasks.md`
  rather than invented per fan-out
- the extractor's two silent behaviours are stated where an author reads them

Non-Goals:
- a `zmx` route for agents
- a machine check on write-set intersection
- a machine check that `MERGE` names a real task
- any agent-initiated pane or editor
- shared-vocabulary work
- rewriting archived changes
- citelock snapshot deduplication

## Decisions

- Decision: the fan-out prohibition is keyed on overlapping write sets, not on
  whether subtasks read each other's output. The apply instruction MUST state
  that a ready set whose declared write sets intersect runs in one context.
- Alternative rejected: key it on shared output, as the first draft did. The
  scheduler releases a subtask only when its dependencies are complete, so no
  ready set contains two tasks with an edge between them. That rule could fire
  only where the fake-edge rule had already been broken, which makes it a
  restatement of the graph rather than a constraint on it.
- Alternative rejected: keep "when parallel work materially helps". A permission
  with no negative case is satisfied by any answer, so it never declines.
- Evidence, recorded honestly: the write-set formulation is what explains the
  fan-out shape this repository actually produces. In the archived change
  `2026-08-05-decompose-flake-checks`, phase 2 fanned six subtasks that each
  added a line to one registry file. That fan-out ran and was correct, and under
  the disjoint-file-set instruction a faithful orchestrator would have refused
  it. The rule therefore has real cases on both sides, which is what the earlier
  formulation lacked.

- Decision: a `graph` phase declares `- **MERGE** <task id>`, naming one subtask
  that reads every sibling's output and owns the merged result. The merge node
  is a coordination point, not a verifier: the schema already places the
  verifier in the per-phase review subtask, and this change does not move that
  responsibility.
- Alternative rejected: leave the merge implicit in the phase's last task. File
  order is exactly what the declared graph exists to stop being load-bearing.
- Alternative rejected: make the merge a human gate. The merge is a synthesis
  step a model performs, and gating it would fire on every fan-out, which the
  tasks instruction's own test rejects as ceremony.
- Alternative rejected: justify the marker with the study's centralized-
  verification finding. That finding is about verification, which this schema
  already has, so it does not reach a coordination marker. The finding is cited
  in the proposal where it belongs, as the reason the per-phase review subtask
  stays.
- Consequence, recorded rather than hidden: `phase-marker-conditional` tests
  presence, so `- **MERGE**` with no value, or naming a task that does not
  exist, passes. The template therefore carries a concrete placeholder id rather
  than an HTML comment.
- Consequence, recorded rather than hidden: the schema admits only `loop` or
  `graph`, so a phase that is a strict chain must declare `graph` and is then
  required to declare a merge that names its terminal node and carries no
  information. Phase 2 of this change is such a phase. The cost is one redundant
  marker per chain phase, accepted because the alternative is a third shape.

- Decision: the write set is declared per `graph` subtask and read by a human.
- Alternative rejected: implement the intersection check in `hack/lint.sh`.
  Every other task-graph rule is a specutil rule, and splitting one rule into a
  second tool means two places to look when a change fails.
- Alternative rejected: omit the marker until the check exists. The marker is
  the input to the prohibition above, which is stated as a rule regardless, and
  the orchestrator needs the set in order to follow the routing paragraph.
- Correction to an earlier draft of this document, recorded rather than hidden:
  the upstream work is not a cheap new instance of an existing rule kind. None
  of the 15 kinds `specutil check --list-rules` reports takes an extracted task
  field as a parameter, so it is a new rule-kind shape.

- Decision: the schema states the two extractor behaviours an author cannot
  otherwise discover. The field pass takes the first match on the line, so prose
  that repeats a marker label captures the prose as the value and truncates the
  rendered task text there. The kind pass strips a leading kind verb, so a task
  opening with `Apply` loses that word in every projection.
- Alternative rejected: leave it to the author to notice. Both misfires happened
  in this change's own `tasks.md`, and neither produced a lint error.
- Alternative rejected: change the extractor to take the last match. It is a
  separate repository, and the last match is equally arbitrary.

- Decision: the adversarial-review section contradiction is fixed everywhere it
  lives. The rubric override stops `specutil check` requiring the section, and
  `templates/design.md` and both `adversarial-review` skill files stop asking
  the author for it.
- Alternative rejected: the rubric override alone. The override only removes the
  check, so the template would still scaffold the section with nothing left to
  flag it.
- Alternative rejected: match the section by its heading form. Two of the three
  files ask for it in running prose with no heading marker, so a pattern
  requiring `## ` is blind to them.

- Decision: `- TERMINAL:` is promoted to `- **TERMINAL**` in the template, in
  the same phase that adds it to the allowlist.
- Alternative rejected: extend the allowlist and leave the marker unbolded. The
  same test this change uses to keep WRITES out of the allowlist, that no
  artifact produces the form, would then apply to TERMINAL. Deleting the note
  that recorded the promotion as a TODO without performing the promotion loses
  the intent instead of closing it.

- Decision: the wezterm workspace switcher spawns a seshy target through `s`,
  and this stays an owner route. `s` is a zsh function rather than an
  executable, so the switcher delegates to an interactive zsh and falls back to
  a plain workspace when that fails.
- Alternative rejected: auto-attach in `.zshrc` when the cwd is under the seshy
  root. The idiomatic form is an `exec`, and an `exec` in `.zshrc` makes every
  shell unusable when zmx is broken or its socket directory is unwritable.
- Alternative rejected: one zmx session per shell with auto-quit. Auto-quit
  removes the only property zmx has, stated in its own module comment as "a
  named shell session that survives a detach, and nothing else."

- Decision: the rubric is part of the managed schema, sourced at
  `modules/home/programs/llm/openspec-schema/specutil.yaml`, with
  `openspec/specutil.yaml` a relative in-repo symlink to it.
- Alternative rejected: author `openspec/specutil.yaml` by hand at the
  repository root. A Nix-managed equivalent exists, so a hand-managed copy is
  the case the repository rule already forbids.
- Alternative rejected: generate the repository copy and add a drift check. A
  symlink has no drift to check.

- Decision: the rubric states `preset: spec-driven` and appends rules rather
  than restating them. `internal/check/check.go` resolves the preset, appends
  `rules:`, lets a rule sharing a preset rule's name replace it, then applies
  `disable:`.
- Alternative rejected: restate all 15 preset rules locally. A local copy would
  silently miss every upstream rule added later.
- Alternative rejected: also add WRITES to the bolded-lead allowlist. The write
  set is an inline task field, so no artifact ever writes `- **WRITES**`.

- Decision: no shared-vocabulary work ships here. An earlier draft claimed one
  concept reached different harnesses as `phase`, `tier`, and `rung`. Measured
  over `modules/home/programs/llm/`, `rung` appears zero times, `stage` never
  denotes a phase, and `applyVocab` substitutes only `{{agent}}` and
  `{{agents}}`, so it cannot produce the defect. The phase is removed rather
  than rewritten, because there is no defect to write it against.
- Alternative rejected: keep the phase and substitute a different vocabulary
  defect for the false one. The candidate synonyms were counted across the tree
  and none denotes a task phase, so retaining the phase would mean writing a
  defect the files do not exhibit in order to preserve a scope decision.
- Alternative rejected: keep the shared-term table with no defect, on the ground
  that one word per concept is good practice regardless. `applyVocab` is a
  render-time substitution, so a table with nothing to correct adds indirection
  to every future edit and changes no rendered output.

## Rollout & Gating

A prerequisite landed first, as commit `992926704`.
`modules/home/programs/llm/runtime/spec-preflight.sh` sets `set -uo pipefail`
deliberately, without `errexit`, because it reports every failing section and
exits once at the end. `writeShellApplication` prepends `set -o errexit`, so
with `pipefail` a `diff` or `grep` that finds nothing aborted the script
part-way through its report. The moment this change added a file to the fork,
the drift section aborted `spec-preflight` before it reached `specutil check`,
and `.githooks/pre-commit` then refused every commit in the repository.

The phases ship in order, and each is reviewable on its own.

1. Schema rules, the rubric, the adversarial-review section fix, and the
   rubric's fixture run against the archived changes. Verified by `specutil
   check` with no argument and by `spec-preflight all
   graph-shaped-task-execution`.
2. The switcher change. Verified by `nix build
   .#darwinConfigurations.lv426.system` and then by running the switcher and
   naming the session, which a build cannot decide.
3. Rollout: `nh darwin switch`, then an owner spot-check.

`specutil check` takes a change name, not a path: `specutil check
openspec/changes/` exits non-zero with "not found". With no argument it checks
every directory under `openspec/changes/` except `archive/`, which today is this
change alone. That is why phase 1 carries a fixture task: it is the only way the
added rules are exercised against input this change did not author.

The gate sequence is the repository default: edit, `hack/lint.sh --all`, `nix
flake check`, `nix build .#darwinConfigurations.lv426.system`, owner spot-check,
`nh darwin switch`. Both hosts render this code, so
`nix eval --raw .#nixosConfigurations.arrakis.config.system.build.toplevel.drvPath`
gates alongside the lv426 build. arrakis is switched by its owner on its own
schedule; until it is, its installed schema lags and `spec-preflight` reports
drift as a note.

Deviation from this order, recorded rather than hidden: the switch that
installed the prerequisite also installed the rubric, because the schema
directory installs recursively and the rubric file was already on disk. Phase
1's task 1.3 deliverable is therefore live on lv426 while phase 1 is
uncommitted. Nothing reads it except `specutil check` in this repository, and
the phase 1 commit brings the source and the installed copy back into agreement.

The kill switch is `git revert` of the phase commit. Nothing here migrates state
or writes outside the store and the rendered dotfiles. A revert leaves the
installed schema ahead of the source until the switch runs, and the drift
section reports that as a note rather than a failure, so the revert commit
itself is not blocked.

## Risks / Trade-offs

- The write-set rule is drawn too tight and declines a fan-out that was correct.
  The archived six-way registry fan-out is exactly that case: it worked, and
  this rule would have refused it. Mitigation: none mechanical. This is the
  first human-owned decision in the proposal, and the owner judges it at 3.2
  after reading the rendered rule.
- Nothing reads the declared write sets, so they drift from what a worker wrote.
  Mitigation: none available here. The upstream rule kind is the fix, and it is
  a new rule-kind shape rather than a cheap addition.
- `- **MERGE**` passes the lint while naming nothing, and is redundant on a
  chain phase. Mitigation: partial, through the template placeholder and the
  human read at each phase boundary.
- The tasks instruction already carries eight rule bullets in about 1374 words,
  and this change adds five more. No command can decide whether a rule that far
  down the file is read. Mitigation: none mechanical. This is the second
  human-owned decision in the proposal, added because the earlier drafts treated
  every defect as a missing rule and never counted the cost of another one.
- An archived change that is later resumed fails a lint it never had to pass.
  Measured by the phase 1 fixture over all 48 archived changes: the local rubric
  adds 74 `graph-declares-merge` findings and removes 21 `design-sections`
  findings, and every other rule count is identical, including
  `bolded-bullet-lead` at 106 either way. Mitigation: the debt is now a number
  rather than a guess. Context that reduces its weight: the preset alone already
  reports 452 findings against those changes, so a resumed archive fails the
  lint today for reasons this change did not introduce.
- The switcher makes a workspace switch depend on `sy` and `zmx`, and on an
  interactive zsh. Mitigation: the fallback to a plain workspace is required by
  task 2.1 and confirmed by task 2.2.

## Migration Plan

No state migrates. The change replaces rendered files, all of which are produced
from the store on each switch.

1. Verify: `hack/lint.sh --all` and `nix flake check` exit 0.
2. Verify: `nix build .#darwinConfigurations.lv426.system` exits 0, and the
   arrakis toplevel evaluates.
3. Apply: `nh darwin switch`.
4. Confirm: the owner reads the rendered fan-out paragraph and decides whether
   the rule says what they meant, and whether the instruction is now too long.

Rollback: `git revert <phase commit>` then `nh darwin switch`. The previous
generation is on disk until the next garbage collection, so
`/nix/var/nix/profiles/system-<n>-link/activate` also restores it directly.

## Open Questions

- Whether the write-set intersection check and the MERGE value check are worth
  adding to `github:roshbhatia/specutil` as a new rule-kind shape that reads an
  extracted task field. Deferred until the marker has been used in two or three
  real changes.
- Whether a strict-chain phase deserves a third shape, so it is not forced to
  declare `graph` and then a merge that names its terminal node.
