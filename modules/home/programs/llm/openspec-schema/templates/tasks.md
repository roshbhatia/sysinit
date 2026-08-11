<!-- A task line states an outcome and its gate. Nothing else.
     `specutil check` warns over 60 words, about four sentences.

     Evidence, findings, corrections, and dates go in an indented block under
     the task line, never into it. The two have opposite update rules: the line
     is the plan and should shrink as work finishes, the block is the record and
     only grows. Merged, every new fact rewrites a prior conclusion in place, so
     the line fills with strikethroughs and no reader can tell what is still
     true. The indented block is also invisible to the review fingerprint, so
     recording evidence there does not restale an approved decision.

     State the outcome, not the mechanism. A task written before any measurement
     that names the package, flag, or assertion to use has guessed, and every
     guess later has to be defended or renegotiated. Name what must be true;
     let the implementer choose how. -->

## 1. <!-- Loop-shaped phase: gather, act, verify, repeat to a stop condition.
        Only use `loop` if the same tasks re-run on iteration 2. If every step
        happens once, this is a graph with a dependency chain. -->

- **SHAPE** loop
- **STOP** `nix flake check` exits 0
        <!-- Replace the command above with this phase's real exit. It MUST name a
             command, or a predicate over one, e.g. `nix flake check` exits 0 and
             each new check fails on an injected defect. Not "it looks right":
             nothing can evaluate that, so the loop would never terminate, and
             `specutil check` rejects it. -->
- **MAX-ITERS** <!-- integer cap; 1 is the valid single-pass case -->
- **TERMINAL** <!-- how this ends WITHOUT success: CAPPED at MAX-ITERS,
                   STALLED after <n> iterations with no change in the STOP
                   metric, or CHURNING. See the `adversarial-review` skill. -->

- [ ] 1.1 Gather: <!-- collect context / inputs -->
- [ ] 1.2 Act: <!-- do the work -->
- [ ] 1.3 Verify: <!-- check against the stop condition; iterate 1.2 if not met -->
- [ ] 1.4 Adversarial review (`adversarial-review` skill): run deterministic lint; run optional critics only when requested or risk-justified

## 2. <!-- Graph-shaped phase: subtasks with dependency edges -->

- **SHAPE** graph
- **MERGE** 2.2
        <!-- Name the ONE subtask that reads every sibling's output and owns the
             merged result. A real id, never a comment: the lint checks that the
             marker is present, not that it names a task, so a placeholder
             comment here passes while naming nothing. -->

<!-- Fanning out to more than five siblings? Name a pilot subtask that runs the
     same work over a smaller input and must finish first. -->

<!-- `writes:` names the paths a subtask may modify. Siblings that can run at
     once MUST have disjoint sets: the apply instruction refuses to fan out a
     ready set whose write sets intersect. -->

- [ ] 2.1 <!-- root subtask --> `deps:` none `writes:` <!-- paths, or none -->
- [ ] 2.2 Merge: <!-- reads 2.1 and every other sibling --> `deps:` 2.1 `writes:` <!-- paths, or none -->
- [ ] 2.3 Adversarial review (`adversarial-review` skill): run deterministic lint; run optional critics only when requested or risk-justified `deps:` 2.2 `writes:` <!-- this change's review.md -->

## 3. Rollout

<!-- A Rollout phase is exempt from the shape and adversarial-review rules. It
     sequences the impactful actions behind their gates.

     Gate on judgment, not on distrust. A precondition a command decides is not
     a gate: name the command on the Apply line. A Confirm task states the
     judgment only a human can make, and there is normally one per action. -->

- [ ] 3.1 Apply: <!-- the impactful action, e.g. nh darwin switch --> , gated on <!-- the command that must exit 0 first -->
- [ ] 3.2 Confirm: <!-- the judgment only a human can make, not a re-run of a command -->
