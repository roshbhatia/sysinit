## MODIFIED Requirements

### Requirement: The adversarial review has a deterministic rubric-lint and a stabilized critique

The mechanical, reproducible part of adversarial review MUST be a deterministic `specutil check` rubric-lint over the change artifacts. It MUST check only facts the author states, never facts it must infer: scenario polarity is declared in a machine-readable body line (for example a `- **POLARITY** negative` line inside the scenario), NOT in the heading. The heading MUST stay the canonical `#### Scenario: <name>`, because openspec's archive-apply parser matches `#### Scenario:` strictly and a heading marker like `#### Scenario [negative]:` makes archive silently drop the scenario. `specutil check` reads the body-line marker rather than guessing polarity from prose. The rosh-spec-driven schema (Slice 1) MUST add the body-line polarity convention so the marker exists to read. The lint checks: every requirement has at least one declared-negative scenario, `design.md` has the `Decisions`, `Rollout & Gating`, and `Adversarial Review` sections, each `Decisions` entry has a declared rejected-alternative marker, every `tasks.md` slice has an adversarial-review checkmark, and `Non-goals` is present when the change touches more than one capability. This lint is a pure function of the artifacts and exits with a code. The LLM critique step MUST NOT be claimed to be deterministic; it is stabilized only (pinned artifact snapshot, fixed rubric, fixed critic prompts, fixed critic count and lens set, temperature 0, structured verdict, majority vote), and the skill MUST state that two runs converge but are not identical.

#### Scenario: Rubric-lint catches a requirement with no declared-negative scenario
- **POLARITY** negative
- **WHEN** `specutil check` runs against a change whose spec adds a requirement whose scenarios are all declared positive (no negative-polarity marker)
- **THEN** it exits non-zero and names the requirement lacking a declared-negative scenario

#### Scenario: Rubric-lint reads declared polarity, not prose
- **POLARITY** positive
- **WHEN** a scenario's THEN prose contains a failure token (for example "non-zero") but its declared body-line polarity marker is positive
- **THEN** `specutil check` treats it as positive per the marker, so the lint verdict does not depend on prose wording, and the canonical `#### Scenario:` heading keeps openspec archive from dropping it

#### Scenario: Critique is not claimed deterministic
- **POLARITY** positive
- **WHEN** the adversarial-review skill documents the critique step
- **THEN** it states the critique is stabilized but not bit-deterministic, and only the `specutil check` rubric-lint is reproducible
