# Pattern selection references

Use these sources as starting points. Read a candidate's individual entry before
recommending it. A catalog name is vocabulary, not evidence that an abstraction
belongs in the current codebase. The selection cautions below are local guidance.

## Martin Fowler

- [Patterns of Enterprise Application Architecture](https://martinfowler.com/eaaCatalog/):
  application logic, persistence, presentation, and boundary patterns. Compare
  Transaction Script with Domain Model before adding an object model; consider
  Service Layer for an actual application boundary, Data Mapper for persistence
  independence, and Repository where a domain-facing collection interface helps.
  Follow the catalog's entry links for the precise intent. Do not add layers only
  to match these names.
- [Catalog of Refactorings](https://refactoring.com/catalog/): concrete
  transformations such as Move Function, Extract Function, Inline Function, and
  Separate Query from Modifier. Select a transformation after identifying the
  ownership or dependency problem; extraction and inlining are both candidates.
- [Branch by Abstraction](https://martinfowler.com/bliki/BranchByAbstraction.html):
  replace a dependency incrementally behind a boundary while the system remains
  releasable. Account for the cost of two implementations and remove migration
  scaffolding when it is no longer needed. Fowler credits Paul Hammant with the
  term and Stacy Curl with the original idea.
- [Strangler Fig](https://martinfowler.com/bliki/StranglerFigApplication.html):
  gradual legacy modernization. Consider it when capabilities can migrate
  independently; identify routing, state ownership, and retirement criteria.
  A local function cleanup rarely needs a migration architecture.

## Microsoft Azure Architecture Center

The [cloud design patterns catalog](https://learn.microsoft.com/en-us/azure/architecture/patterns/)
organizes patterns by the problems they address and their tradeoffs. Choose by
workload constraints; Azure-specific examples are implementation illustrations.

- [Anti-Corruption Layer](https://learn.microsoft.com/en-us/azure/architecture/patterns/anti-corruption-layer):
  translate between different subsystem semantics. Use a real translation
  boundary, not a renamed pass-through. Microsoft attributes the pattern to
  Eric Evans. Consider translation maintenance and added latency.
- [Retry](https://learn.microsoft.com/en-us/azure/architecture/patterns/retry):
  transient dependency failures. Check bounded attempts, delay, idempotency, and
  duplicate effects before changing retry behavior. A retry is not inherently
  evidence of a design defect.
- [Circuit Breaker](https://learn.microsoft.com/en-us/azure/architecture/patterns/circuit-breaker):
  stop repeatedly calling a dependency likely to keep failing. It addresses a
  different condition from transient retries and adds recovery state. Require a
  demonstrated failure problem before adding it.

For other concerns, follow the catalog to the relevant entry, such as Bulkhead,
Cache-Aside, Queue-Based Load Leveling, CQRS, or Strangler Fig. Do not introduce
queues, caches, independently deployed services, or separate read/write models
solely because a pattern exists. Explain their consistency, failure, and operating
costs in the proposal when relevant.
