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
     sequences the impactful actions behind their verification gates. -->

- [ ] 3.1 Verify: <!-- preconditions, e.g. nix flake check and nh darwin build green, diff reviewed -->
- [ ] 3.2 Apply: <!-- the impactful action, e.g. nh darwin switch -->
- [ ] 3.3 Confirm: <!-- postconditions, e.g. expected files exist, owner spot-checks -->
