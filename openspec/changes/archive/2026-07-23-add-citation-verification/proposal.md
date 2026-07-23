## Why

External-factual claims in proposals and designs (pricing, availability, API behavior, cited papers, tool versions) are unverified today. An agent can cite a real URL that does not actually state the claim, and the adversarial-review loop re-litigates "is this link real" every round instead of adjudicating the argument. The recent by-hand twelve-item sourced-evidence pass on a Crossplane doc should become a check that returns an exit code. Pin facts into a lockfile, verify against the pinned snapshot rather than the live web, and quarantine the one irreducibly-fuzzy step into the smallest box.

## What Changes

- Define a `citations.lock` format next to each change. A record is: claim id, source URL or DOI, accessed date, a verbatim quote span copied from the source, and a sha256 of the captured snapshot the quote came from.
- Add a `citelock` verifier (`hack/citelock.sh`). Its offline gate is a pure function of (artifact plus lockfile): format lint (every record has all fields), capture-provenance (the snapshot was tool-captured, not hand-authored), quote-anchor match (`grep -F` the verbatim quote inside the pinned snapshot), snapshot integrity (re-hash and compare), and freshness (accessed date within a per-claim-class threshold). No network, so it is deterministic and offline-safe.
- Add a `citelock capture` step that catches hallucination at authoring time. It fetches the cited URL live (static fetch via `curl`, or `monolith` for single-file HTML) and fails closed: it refuses to write the snapshot unless the verbatim quote is a literal substring of the fetched bytes. On success it writes the captured text and a provenance record (URL, fetch timestamp, HTTP status, content hash). Client-side-rendered SPA sources are out of the citable set (capture does not run JS); the author cites a stable or archived URL or the underlying JSON API instead, so no headless browser is needed. Capture is the truth-check; the offline gate only reproduces its verdict.
- Run the live-web checks at capture time, not in the gate. `lychee` link liveness and the Crossref REST DOI and retraction query (`curl` plus `jq`) run inside `citelock capture` (and `citelock capture --recheck`) and fail closed there. This needs no gating CI, because capture is the enforcement point. They enforce an `https`-only allowlist, reject `file://`, loopback, link-local, and RFC-1918 targets, and pass every lockfile value as an inert argument.
- Add `lychee`, `monolith`, and `jq` from nixpkgs. No source build and no headless browser are needed. `citecheck` is deliberately not used: it is an MCP server, and an MCP tool fires at model discretion, so it cannot be a deterministic gate. The Crossref REST query replaces it.
- Wrap the offline gate as a `nix flake check` and a pre-commit hook. A `CITELOCK_OFFLINE=1` escape and the offline-only default mean a valid change commits on a plane without `--no-verify`.
- Add the schema rule to `rosh-spec-driven`: a change with external-factual claims (pricing, availability, external API behavior, cited papers) MUST carry a `citations.lock`; an unresolved or unanchored claim is a named default-reject. A sha256 or lockfile pin excludes only the bare version identifier it pins (`nvfetcher` `_sources`, `flake.lock`, `vendorHash`), so a routine bump needs no lock; but prose asserting a fact about that version (behavior, history, capabilities) is not covered by the pin and stays in the claim class.
- Add a `citation-verification` skill that teaches the authoring loop. It names `citation-intelligence` (run locally) as an optional, non-deterministic source-ranking aid that is barred from the gate.
- Add a citation lens to the `adversarial-review` skill (Tier 2): a single temperature-0 adjudication of whether the pinned quote supports the claim (SUPPORTS, CONTRADICTS, or UNRELATED), which runs only after Tier 0 is green.

### Non-goals

- Verifying internal or in-repo claims; the gate covers external-factual claims only.
- Live-web verification inside the offline gate; the offline gate runs against the pinned snapshot only.
- arXiv resolution; it is out of scope.
- Auto-fetching sources during the offline gate; fetching happens only at `citelock capture` time, not in the pre-commit or build gate.
- A gating CI as the enforcement point; capture-time fail-closed is the enforcement point, and a CI re-check is optional future work.
- Using `citation-intelligence` in the gate; it is non-deterministic and stays an authoring aid.
- Defending against a determined human who forges `citelock capture` output; the threat model is agent hallucination and accidental paraphrase, not a hostile author.

## Capabilities

### New Capabilities

- `citation-verification`: the lockfile format, the Tier 0 deterministic gate, the capture step, the tool packaging, the authoring skill, and the Tier 2 adjudication lens.

### Modified Capabilities

- `openspec-customization`: the schema requires a `citations.lock` for changes with external-factual claims.

## Impact

- Affected files: new `hack/citelock.sh` and a `Taskfile` entry, a new flake check and pre-commit hook wiring, `modules/home/packages.nix` for the CLIs, a new `modules/home/programs/llm/skills/citation-verification.nix` plus `default.nix` registration, `openspec/schemas/rosh-spec-driven/schema.yaml` and templates plus `CHANGES.md`, and `modules/home/programs/llm/skills/adversarial-review.nix` plus its methodology reference.
- Impactful actions that need human-verification checkpoints in `tasks.md`:
  - `nh darwin switch`: installs the new CLIs, the skill, and the pre-commit hook.
  - No writes to external services; `lychee` and the Crossref REST query read external state but do not mutate it.
- Dependency: this change depends on `default-rosh-spec-driven-schema`. The schema delta must apply in every project, which requires the XDG install from that change. Both changes modify `openspec-customization`; this change's delta is additive. Archive `default-rosh-spec-driven-schema` first.
- Gating signal: `nix flake check` (validate plus the new citelock check) then `nh darwin build` then a user smoke test (citelock on a sample lock with a deliberately wrong anchor exits non-zero) then `nh darwin switch`. The pre-commit hook is the per-commit kill point; the flake check is the per-build kill point.
