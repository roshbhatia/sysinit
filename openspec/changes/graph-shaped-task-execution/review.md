## Rubric

- the proposal `Behavior` criteria, all three groups
- the design `Decisions` and each recorded rejected alternative
- the design `Rollout & Gating` sequence
- the proposal `Non-goals`, in particular that no agent-initiated pane is added

An objection that cites no item above is out of scope and is discarded.

## Recommendation

Recommendation: do not run

This recommendation was wrong, and both rounds are the evidence. Its four
arguments held only for the rules the change adds. None covered whether the
change's premises were true, whether the plan could be committed at all, or
whether the commands the criteria name decide what they claim. Rounds 1 and 2
broke all three. The original reasoning is not reproduced here, because keeping
a refuted argument beside its refutation invites it to be read as still
standing.

## Owner decision

Decision: run approved
Decided by: owner
Date: 2026-08-09

The owner decided against the recommendation above.

At the round 2 boundary the loop reached a hand-back state and the recommended
option was to cut the change to the three items that survived every lens. The
owner chose to keep full scope and revise against all 16 objections. That
decision is recorded here rather than argued with, and the revisions below
implement it.

## Deterministic lint

`specutil check --change graph-shaped-task-execution` reads
`openspec/changes/graph-shaped-task-execution/specutil.review.yaml`, written by
`specutil review set`. It does not read this file's prose. The record is written
after the round 2 revisions land, because it fingerprints the artifacts it
describes.

`citelock verify`: exit 0, offline gate passed, 4 records.

`spec-preflight all graph-shaped-task-execution`: aborted part-way through its
own report until the prerequisite fix landed. See round 1, ops 1.

## Rounds

### Round 1

Three read-only critics, fresh context, authorship hidden. Lenses: reuse,
ops/rollback, correctness. 14 surviving objections, every one upheld and fixed.

Reuse:

- r1. The runner already existed, so the change's fourth defect was false.
  `schema.yaml` already routes a concurrent ready set to teammates and
  fresh-context subagents, and `zmx run` sends a shell command line, so it
  cannot author a schema template. The zmx phase was deleted.
- r2. One session per subtask would have put `seshy-1.2` in the owner's
  namespace, breaking the change's own non-goal. Fixed by r1.
- r3. Phase 3 held two unrelated concerns and contained a fake edge. Split.
- r4. Merge and review nodes declared no write set. Fixed.

Ops and rollback:

- o1. The plan's own first commit was refused. `spec-preflight` inherits
  `set -o errexit` from `writeShellApplication`, and its drift section aborted
  before `specutil check` and every later section. Fixed by `set +o errexit`,
  landed as commit `992926704` and verified under the wrapper's flags.
- o2. The block was repository-wide, and CI could not see it: with no installed
  schema, preflight notes "not found" and continues. Fixed by o1.
- o3. The stated kill switch could not be committed, because a revert leaves the
  installed copy ahead of the source. Fixed by o1.
- o4. Task 4.3's gate could never pass; two gates read two different artifacts.
  Fixed in the Deterministic lint section above.
- o5. arrakis was never evaluated, and renders the same tree. Now a gate.

Correctness:

- c1. Task 1.1's write-set marker matched the literal label in its own prose, so
  `specutil render` truncated the task mid-sentence. Fixed.
- c2. `graph-declares-merge` passes on an empty or dangling MERGE. Fixed as far
  as this repository can, through the template placeholder, and recorded.
- c3. The rubric override did not fix the contradiction once: the template and
  the skill text still ask for the section. Fixed.
- c4. The stale TERMINAL note lives in `schema.yaml`, not the template. Fixed.
- c5. `specutil check openspec/changes/` is not a valid invocation. Fixed.

Found while verifying, not raised by a critic: task 2.2 opened with `Apply`,
which the extractor strips as a kind verb.

### Round 2

Three read-only critics, fresh context. Lenses: citation, fix-induced
regression, scope and cost. 16 surviving objections. The count rose, and three
were caused by round 1's own fixes, so the loop reached a hand-back state.

Scope and cost:

- s1. Every Must-do criterion was a grep over the file being edited, so nothing
  failed if a model ignored every new rule. Fixed in part: a fixture criterion
  now runs the added rubric rules against the archived changes, which this
  change did not author. The prose rules remain unmeasurable and that is now a
  stated human-owned decision.
- s2. The anti-fan-out prohibition had an empty extension. `specutil next`
  releases a subtask only when its dependencies are complete, so a ready set
  never holds two tasks with an edge between them. Verified directly. Fixed by
  re-keying the rule on overlapping write sets, which can fire on an honest
  graph.
- s3. Two of three graph phases were strict chains, making MERGE
  information-free. Partly fixed: removing the fake edge makes phase 1 a real
  3-wide fan-out. Phase 2 is still a chain, and the cost is now recorded.
- s4. Edge 1.4 to 1.3 failed the change's own fake-edge test. Removed.
- s5. The write set was inert, and no specutil rule kind reads a task field, so
  the upstream work is a new rule-kind shape rather than a cheap addition. Fixed
  in part: the marker is now the input to the fan-out rule, so it is read by the
  rule that governs the ready set. The correction about upstream cost is
  recorded in the design.
- Secondary, upheld: an archived six-way fan-out had non-disjoint write sets and
  was correct. It is now the design's worked example on both sides of the rule.
  Instruction growth was unacknowledged and is now a risk and a human-owned
  decision.

Citation:

- v1. The centralized-verification quote was unrelated to the MERGE decision,
  and the proposal's own next sentence conceded verification already exists.
  Fixed: the MERGE decision no longer cites it, and the quote now supports the
  claim it does fit, that the per-phase review subtask stays.
- v2. The design carried two external claims with no cite marker, one of which
  was the unpinnable `graph-engineering` numeric comparison the design's own
  rejected alternative forbids writing. Fixed by deleting the comparison and
  moving all empirical material to the proposal.
- v3. The anti-fan-out cite was a leap from whole-benchmark architecture
  selection to ready-set scheduling. Fixed in part: the better-fitting finding,
  that tool-heavy tasks incur multi-agent overhead, is now captured and cited.
  Some distance between the study and this repository remains.
- v4. "The controlled evidence says the negative case is the expensive one"
  over-read a symmetric sentence whose positive magnitude is larger. Fixed: the
  inference is now attributed to the author and the range is stated in both
  directions.
- v5. `claim_class: research` is outside citelock's vocabulary, the source URL
  was unversioned, and no record carried a DOI. Fixed for the first two by
  recapturing all records as `paper` against `2512.08296v3`. The DOI suggestion
  is refused with evidence: citelock resolves DOIs through Crossref, arXiv
  registers `10.48550/*` with DataCite, and adding it made capture fail.

Fix-induced regression:

- g1. Must-do criterion 5 could never pass, because task 1.3 plants the searched
  string inside the grep root, and its pattern was blind to two of the three
  files task 1.4 writes. Fixed: the root excludes the rubric file, the pattern
  drops the heading marker, and the rubric comment no longer spells the heading.
  Verified to return exactly 3 hits now and zero after task 1.4.
- g2. Must-do criterion 7 was decided by no task, and `s` is a zsh function that
  Lua cannot call as task 3.1 described. Fixed: task 2.2 runs the switcher and
  names the session, the check is made discriminating by killing the session
  first, and the delegation mechanism is now stated.
- g3. The vocabulary defect was false. `rung` appears zero times in the tree,
  `stage` never denotes a phase, and `applyVocab` substitutes only two
  placeholders. This is the one objection with no fix that preserves scope:
  keeping the phase would have meant writing a defect the files do not exhibit,
  so the phase is deleted and the reason recorded in the design.
- g4. TERMINAL in the allowlist failed the exact test used to reject WRITES.
  Fixed by promoting the marker in the template in the same phase.
- g5. The Must-still-hold rubric net covered one change, itself. Fixed in part
  by the fixture task; the criterion's scope is stated honestly and the resume
  hazard is now a risk.
- g6. Phases 2 and 3 declared a merge on pure chains. Same disposition as s3.
- Verified sound by this lens and not re-fixed: the `errexit` fix swallows
  nothing and still exits 1; render truncation is gone; the rubric override is
  live and load-bearing; `bolded-bullet-lead` is regression-free against four
  archived changes.

### Phase 1 implementation

Adversarial review: not run; deterministic lint passed. No critic was spawned.
The plan itself already took two full rounds, and phase 1 implements exactly
what those rounds settled, so a third critic pass would re-read a text no
objection touched.

Evidence rather than assertion:

- `hack/lint.sh` passes every stage. The one failure during the phase was
  `review-decision-current` reporting the record stale, which is the record
  doing its job after the task checkboxes moved.
- The three Behavior criteria for task 1.1 each returned 0 before the edit and
  return non-zero after: `reads the`, `write sets`, and `first match`.
- The adversarial-review section criterion returned 3 hits before task 1.4 and
  returns none after.
- The template emits `- **TERMINAL**` exactly once, so the allowlist entry now
  corresponds to a form an artifact produces.
- `specutil render --as tickets` renders all 14 task lines in full, so neither
  extractor collision recurred.
- The fixture over all 48 archived changes is the phase's strongest evidence,
  because it exercises the added rules against input this change did not write:
  `graph-declares-merge` goes from 0 to 74, `design-sections` falls from 33 to
  12, and every other rule count is unchanged.
- `nix eval` on the lv426 system drvPath succeeds.

### Phase 2 implementation

Adversarial review: not run; deterministic lint passed. No critic was spawned.
The phase changes one function in one file, and its risk is concentrated in a
check no critic can run either.

Evidence rather than assertion:

- `hack/lint.sh` passes, including `stylua`, and `luac -p` parses the changed
  file. `nix build .#darwinConfigurations.lv426.system` exits 0.
- The declared write set was wrong and was corrected rather than worked around.
  Task 2.1 named `switcher.lua`, but that file already passes the spawn
  directory to `actions.lua`, and the fix belongs in the callee. This is the
  first live instance of the drift the design records as an accepted risk: the
  declaration is not checked, so it was wrong until a human read it.
- The positive path is not claimed. Opening a workspace from the switcher needs
  a keystroke in a running GUI, so the check moved to the owner at task 3.2 and
  the Behavior criterion now says so. Marking it here would have been a claim
  with no evidence behind it.
- The fallback is structural rather than tested: the spawned command ends in
  `exec zsh -i`, so an undefined `s`, or its own `command -v` guards declining,
  still leaves a plain shell in the same directory.

## Terminal state

State: STALLED
Rounds run: 2
Surviving-objection trend: 14, 16

The count rose rather than declined, and three round 2 objections were caused by
round 1's fixes. Both stop-early conditions fired, so the loop handed back
rather than running round 3. The owner then directed a full-scope revision
against all 16, which is what the round 2 entries above record. This is not a
clean terminal state and must not be read as one.

## Open objections

- The prose rules cannot fail a check. The fake-edge test, the write-set
  prohibition, and the two extractor rules are instructions, and a model that
  ignores all four still passes every criterion except the fixture run. Only the
  rubric-backed rules are machine-decided.
- `- **MERGE**` is redundant on a strict-chain phase, and phase 2 of this change
  is one. The schema admits no third shape, so the marker is required where it
  names nothing.
- Nothing reads the declared write sets, so they can drift from what a worker
  wrote. The rule that consumes them is prose.
- The write-set rule would have refused an archived six-way fan-out that was
  correct. Whether it is drawn in the right place is unresolved and is the first
  human-owned decision.
- The tasks instruction grows from eight rule bullets to thirteen, and no
  command can decide whether a rule that far down the file is read. This is the
  second human-owned decision.
- An archived change resumed after this lands fails a lint it never had to pass.
  The fixture task measures the size of that debt but does not pay it.
