## 1. <!-- Loop-shaped phase: gather, act, verify, repeat to a stop condition -->

- **SHAPE** loop
- **STOP** <!-- the condition that ends the loop, e.g. all fixtures pass -->
- **MAX-ITERS** <!-- integer cap; 1 is the valid single-pass case -->

- [ ] 1.1 Gather: <!-- collect context / inputs -->
- [ ] 1.2 Act: <!-- do the work -->
- [ ] 1.3 Verify: <!-- check against the stop condition; iterate 1.2 if not met -->

## 2. <!-- Graph-shaped phase: subtasks with dependency edges -->

- **SHAPE** graph

- [ ] 2.1 <!-- root subtask --> `deps:` none
- [ ] 2.2 <!-- depends on 2.1 --> `deps:` 2.1
