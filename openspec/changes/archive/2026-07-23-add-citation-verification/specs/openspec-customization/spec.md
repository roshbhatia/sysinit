## ADDED Requirements

### Requirement: The schema requires a citations.lock for external-factual claims

The `rosh-spec-driven` schema MUST require that a change containing external-factual claims (pricing, availability, external API behavior, cited papers) carries a `citations.lock` that passes `citelock`. The exclusion is scoped narrowly: a sha256 or lockfile pin (`nvfetcher` `_sources`, `flake.lock`, `vendorHash`) excludes only the bare version identifier it pins, because the hash is provenance for the fetched bytes. Any prose claim about that version's behavior, history, or capabilities (for example "the first release with fix X", "this version adds Y") is NOT covered by the pin and remains in the claim class. This separates byte-provenance from claim-provenance, so a routine bump with no descriptive prose needs no lock, while a bump whose prose asserts a fact about the version does. An unresolved or unanchored external-factual claim is a named default-reject, in the same register as the "parallel infrastructure" default-reject. The rule MUST be encoded in the proposal and design instructions and recorded in `openspec/schemas/rosh-spec-driven/CHANGES.md`.

The determination of whether a change "has external-factual claims" is a review-gate judgment (the author and the adversarial-review critics), not a mechanical one. `citelock` is mechanical only once a `citations.lock` exists: it is a no-op that exits zero when no lock is present. The schema rule closes the gap by making an unanchored claim a default-reject at the review gate, so a missing lock on a change that clearly makes external claims is caught by review, not silently passed.

#### Scenario: Claim rule surfaced at authoring time
- **POLARITY** positive
- **WHEN** an agent invokes `openspec instructions proposal --change <name>` for a change with external-factual claims
- **THEN** the returned instruction text states that a `citations.lock` is required and that an unanchored claim is a default-reject

#### Scenario: Unanchored claim blocks the review gate
- **POLARITY** negative
- **WHEN** a change asserts an external-factual claim with no matching passing record in `citations.lock`
- **THEN** the review gate treats the change as default-reject and the slice is not marked done

#### Scenario: Change with no external claims is not blocked
- **POLARITY** positive
- **WHEN** a change makes no external-factual claims and carries no `citations.lock`
- **THEN** `citelock` exits zero as a no-op and the review gate does not require a lock

#### Scenario: Bare version bump is not blocked
- **POLARITY** positive
- **WHEN** a change only bumps `nvfetcher` `_sources`, `flake.lock`, or a sha256-pinned version and its prose asserts no fact about the version beyond the identifier
- **THEN** the review gate does not require a lock, because the pin is provenance for the bare version

#### Scenario: Version bump with a descriptive claim needs a lock
- **POLARITY** negative
- **WHEN** a bump's prose asserts a fact about the version (for example "the first release with fix X") not attested by the sha256
- **THEN** that prose is in the claim class and the review gate requires a `citations.lock` record for it
