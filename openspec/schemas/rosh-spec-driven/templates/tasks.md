## 1. <!-- Loop-shaped phase: gather, act, verify, repeat to a stop condition -->

- **SHAPE** loop
- **STOP** <!-- the condition that ends the loop, e.g. all fixtures pass -->
- **MAX-ITERS** <!-- integer cap; 1 is the valid single-pass case -->

- [ ] 1.1 Gather: <!-- collect context / inputs -->
- [ ] 1.2 Act: <!-- do the work -->
- [ ] 1.3 Verify: <!-- check against the stop condition; iterate 1.2 if not met -->
- [ ] 1.4 Adversarial review (`adversarial-review` skill): critics attempt to break this phase against its spec scenarios, the design decisions, and the rollout gates

## 2. <!-- Graph-shaped phase: subtasks with dependency edges -->

- **SHAPE** graph

- [ ] 2.1 <!-- root subtask --> `deps:` none
- [ ] 2.2 <!-- depends on 2.1 --> `deps:` 2.1
- [ ] 2.3 Adversarial review (`adversarial-review` skill): critics attempt to break this phase against its spec scenarios, the design decisions, and the rollout gates `deps:` 2.2

## 3. Rollout

<!-- A Rollout phase is exempt from the shape and adversarial-review rules. It
     sequences the impactful actions behind their gates.

     Gate on judgment, not on distrust. A precondition a command decides is not
     a gate: name the command on the Apply line. A Confirm task states the
     judgment only a human can make, and there is normally one per action. -->

- [ ] 3.1 Apply: <!-- the impactful action, e.g. nh darwin switch --> , gated on <!-- the command that must exit 0 first -->
- [ ] 3.2 Confirm: <!-- the judgment only a human can make, not a re-run of a command -->
