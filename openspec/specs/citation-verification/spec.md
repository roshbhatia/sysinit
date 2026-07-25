# citation-verification Specification

## Purpose
TBD - created by archiving change add-citation-verification. Update Purpose after archive.
## Requirements
### Requirement: A citations.lock pins every external-factual claim

Each change with external-factual claims MUST carry a `citations.lock` next to its artifacts. Every record MUST have: a claim id, a source URL or DOI, an accessed date, a verbatim quote span copied from the source, and a sha256 of the captured snapshot the quote came from. Verification runs against the pinned snapshot, not the live web, so the same inputs return the same verdict.

#### Scenario: Complete record passes the format lint
- **POLARITY** positive
- **WHEN** `citelock` runs against a `citations.lock` where every record has all required fields
- **THEN** the format-lint stage exits zero

#### Scenario: Missing field rejected
- **POLARITY** negative
- **WHEN** a record omits the verbatim quote span or the snapshot sha256
- **THEN** `citelock` exits non-zero and names the claim id and the missing field

### Requirement: Capture fetches the live source and fails closed on a non-anchoring quote

Hallucination is caught at capture time, not by the offline gate. `citelock capture` MUST fetch the cited URL live (static fetch via `curl`, or `monolith` for single-file HTML) and MUST fail closed: it refuses to write the snapshot and record unless the author's verbatim quote is a literal substring of the fetched bytes. On success it writes the captured text plus a provenance record (URL, fetch timestamp, HTTP status, content hash of the fetched bytes). This is where "a real URL that does not state the claim" is rejected, because the quote is checked against bytes the author did not write.

Client-side-rendered pages (SPAs whose quote appears only after JS runs, for example some cloud pricing pages) are out of the citable set: capture does not execute JS, so the quote will not anchor in the fetched bytes and capture fails closed. The author MUST cite a statically-fetchable source instead: a stable or archived URL (for example a Wayback snapshot) or the underlying JSON API. This keeps capture free of a headless-browser dependency and avoids a one-time render nobody can reproduce; the skill MUST document this and how to find a stable URL.

The offline gate reproduces capture's verdict; it does not independently re-verify against the live source. It confirms a capture-provenance record is present and internally consistent. A determined actor who bypasses `citelock capture` and hand-writes a snapshot plus a matching provenance record is out of the threat model; the offline gate cannot distinguish that forgery without a network fetch, and this limitation MUST be stated plainly in the skill.

#### Scenario: Capture rejects a non-anchoring quote
- **POLARITY** negative
- **WHEN** `citelock capture` fetches the URL and the author's verbatim quote is not a substring of the captured text
- **THEN** capture exits non-zero, writes no snapshot, and names the claim id as non-anchoring against the live source

#### Scenario: Client-rendered source is rejected with guidance
- **POLARITY** negative
- **WHEN** the cited source is a client-side-rendered SPA whose quote is present only after JS runs
- **THEN** capture fails closed (the quote is not in the fetched bytes), names the claim id, and directs the author to cite a stable or archived URL or the underlying JSON API

#### Scenario: Hand-authored snapshot without provenance
- **POLARITY** negative
- **WHEN** a record references a snapshot that has no `citelock capture` provenance record (for example a hand-written text file)
- **THEN** the offline gate exits non-zero and names the claim id as lacking capture provenance

### Requirement: The quote must anchor in the pinned snapshot

`citelock` MUST confirm the record's verbatim quote appears as a substring of the pinned snapshot, using a literal (`grep -F`) match, not a fuzzy or semantic one. This catches a real source that does not actually state the claim. This stage is offline: it reads only the pinned snapshot.

#### Scenario: Quote present
- **POLARITY** positive
- **WHEN** the verbatim quote is a literal substring of the snapshot
- **THEN** the quote-anchor stage exits zero for that claim

#### Scenario: Quote absent from snapshot
- **POLARITY** negative
- **WHEN** the verbatim quote is not a literal substring of the snapshot (for example the agent paraphrased or cited the wrong page)
- **THEN** `citelock` exits non-zero and names the claim id as unanchored

### Requirement: The snapshot must match its recorded hash

`citelock` MUST re-hash the stored snapshot and compare it to the sha256 in the record. A snapshot that has been edited after capture MUST fail.

#### Scenario: Snapshot intact
- **POLARITY** positive
- **WHEN** the re-hashed snapshot equals the recorded sha256
- **THEN** the integrity stage exits zero for that claim

#### Scenario: Snapshot tampered
- **POLARITY** negative
- **WHEN** the stored snapshot no longer hashes to the recorded sha256
- **THEN** `citelock` exits non-zero and names the claim id as an integrity failure

### Requirement: Live-web checks run at capture time, not in the offline gate

Link liveness (`lychee`) and DOI existence and retraction (the public Crossref REST API via `curl` and `jq`) run at `citelock capture` time, alongside the fetch, and fail closed there. They are NOT part of the offline commit or build gate, because they depend on live network state. A retraction discovered after capture is caught on the next `citelock capture --recheck` (an authoring action), not by the offline gate, which only reproduces the pinned verdict. This design needs no gating CI, because capture is the enforcement point; an optional CI re-check MAY be added later but is not required. `citelock` MUST NOT use `citecheck` or any MCP tool. Results MUST be cached on disk. A transient network error at capture MUST degrade to a skip-with-warning, and the offline gate MUST stay green offline.

#### Scenario: Dead or retracted source rejected at capture
- **POLARITY** negative
- **WHEN** `citelock capture` (or `--recheck`) finds a URL returns a non-transient hard failure, or a DOI is retracted
- **THEN** capture exits non-zero and names the affected claim id

#### Scenario: Offline commit stays green
- **POLARITY** positive
- **WHEN** the pre-commit hook runs with no network, or `CITELOCK_OFFLINE=1` is set
- **THEN** only the offline gate runs, no live fetch is attempted, and a valid pinned lock passes without `--no-verify`

### Requirement: Live-web fetches reject unsafe targets and never interpolate into a shell

Before any fetch, `citelock` MUST enforce an `https`-only scheme allowlist and reject `file://`, link-local (`169.254.0.0/16`), loopback (`127.0.0.0/8`), and RFC-1918 hosts. Every lockfile-derived value (URL, DOI) MUST be passed as an inert argument, never interpolated into a command string, so a crafted field cannot execute a shell command or reach an internal endpoint.

#### Scenario: Live link and valid DOI over https
- **POLARITY** positive
- **WHEN** `citelock capture` runs and every URL is a reachable `https` public host and every DOI exists and is not retracted
- **THEN** the liveness stage exits zero

#### Scenario: SSRF or injection target rejected
- **POLARITY** negative
- **WHEN** a lockfile record's source is `file:///etc/passwd`, an `http://169.254.169.254/...` metadata endpoint, a loopback or RFC-1918 host, or a DOI field containing shell metacharacters
- **THEN** `citelock` refuses the fetch, exits non-zero, and names the claim id, and no request or shell command is executed for that value

### Requirement: Freshness is enforced per claim class

Each claim MUST declare a claim class. `citelock` MUST fail a record whose accessed date is older than the threshold for its class (short for pricing and availability, effectively unbounded for published papers). The check is date arithmetic and is deterministic.

#### Scenario: Fresh pricing claim
- **POLARITY** positive
- **WHEN** a pricing-class claim was accessed inside its freshness threshold
- **THEN** the freshness stage exits zero for that claim

#### Scenario: Stale pricing claim
- **POLARITY** negative
- **WHEN** a pricing-class claim was accessed before its freshness threshold
- **THEN** `citelock` exits non-zero and names the claim id as stale

### Requirement: The offline gate is a pure function and Tier 2 runs only after it is green

The offline gate MUST consist only of the snapshot-local stages that need no network: format lint, capture-provenance, quote-anchor (`grep -F`), snapshot integrity (sha256), and freshness arithmetic. These are a pure function of (artifact plus lockfile) and gate the pre-commit hook and `nix flake check` with an exit code. The gate MUST NOT depend on an MCP tool or on a live fetch, because both reintroduce non-determinism. The single LLM adjudication (Tier 2, does the pinned quote support the claim) MAY run only after the offline gate exits zero. `citation-intelligence` MUST NOT be part of the gate.

#### Scenario: Gate wired as a build and commit check
- **POLARITY** positive
- **WHEN** a change carries a `citations.lock` and `nix flake check` runs
- **THEN** the offline stages of `citelock` run as a flake check and their exit code gates the build, with no MCP tool and no live fetch in the path

#### Scenario: Tier 2 attempted before Tier 0 is green
- **POLARITY** negative
- **WHEN** the Tier 2 adjudication is requested while `citelock` (Tier 0) is failing for the change
- **THEN** the adversarial-review citation lens does not run and reports that Tier 0 must pass first

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

