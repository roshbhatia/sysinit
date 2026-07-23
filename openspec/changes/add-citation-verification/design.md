## Context

Adversarial review currently spends rounds confirming links are real instead of adjudicating whether a source supports a claim. There is no mechanical citation gate. Non-determinism lives in two places, not one. First, the trigger: whether a change "has external-factual claims" that require a lock, including the "bare version identifier versus a fact about the version" distinction, is an irreducible review-gate judgment, not a mechanical test. Second, the adjudication: deciding whether a source supports a claim is LLM judgment. What is mechanical and deterministic is narrower: citelock's exit code once a lock exists, and capture's fail-closed anchor against fetched bytes. The design pins those and is honest that the trigger and the adjudication stay judgments. This change treats facts like a lockfile: pin the inputs, make the check a pure function of (artifact plus lockfile), and quarantine the fuzzy step into the smallest box. It depends on `default-rosh-spec-driven-schema`, because the schema rule must apply in every project.

Tool survey: `lychee` (0.24.2) and `monolith` (2.10.1) are in nixpkgs, as is `jq`. No source build is needed. `citecheck` was considered for the DOI and retraction stage, but it is an MCP server (a TypeScript research prototype, arxiv 2603.17339), not the deterministic CLI it was first taken to be, so it is barred from the gate by the same rule that bars every MCP tool. DOI existence and retraction are instead queried against the public Crossref REST API, which needs no key.

Threat model: the gate defends against agent hallucination and accidental paraphrase, an agent citing a real URL that does not state the claim. It does not defend against a determined human who forges the capture tool's output. `citelock capture` performs the fetch and records provenance so a hand-written snapshot is rejected, but a human who reproduces the capture format can still forge; that is out of scope.

Gate boundary: the truth-check happens at `citelock capture` time, which fetches the live source and fails closed if the quote does not anchor in the fetched bytes. The offline gate is a pure function of (artifact plus lockfile), needs no network, and only reproduces capture's verdict, so it is what the pre-commit hook and `nix flake check` run. This repo pushes straight to main with no gating CI, so capture-time enforcement, not CI, is what actually catches a bad claim. An optional CI re-check is future work, not a dependency.

Honesty boundary: the offline gate cannot distinguish a genuine capture from a hand-written snapshot plus a forged provenance record, because that distinction needs a network fetch. Capture is the point where the quote is checked against bytes the author did not write. A determined actor who skips capture and forges provenance defeats the offline gate; that is out of the threat model and is stated in the skill.

## Goals / Non-Goals

**Goals:**

- Citation checking returns a reproducible exit code, not a review opinion.
- The failure mode "real URL that does not state the claim" is caught by a literal string match.
- The one LLM step is small, stable, and runs over a fixed sentence.

**Non-Goals:**

- Internal or in-repo claim checking.
- Live-web verification in the gate.
- arXiv resolution.

## Decisions

- Decision: A citation is a lock record (claim id, source, accessed date, verbatim quote, snapshot sha256), not a bare URL.
  - Alternative rejected: store only the URL and re-fetch at check time. Rejected because the check would then depend on live-web state and never be reproducible.

- Decision: The quote-anchor check is a literal `grep -F` substring match against the snapshot.
  - Alternative rejected: a semantic or embedding match. Rejected because it reintroduces model judgment into Tier 0 and is not reproducible.

- Decision: The gate is CLIs wired into `nix flake check` and a pre-commit hook.
  - Alternative rejected: expose verification as an MCP tool. Rejected because an MCP tool fires at model discretion, so it cannot be a deterministic gate.

- Decision: The enforcement point is `citelock capture`, which fetches live and fails closed on a non-anchoring quote; the offline gate (format, provenance, anchor, integrity, freshness) only reproduces that verdict and gates the pre-commit hook and build, with a `CITELOCK_OFFLINE=1` escape.
  - Alternative rejected: run `lychee` and Crossref in the pre-commit gate. Rejected because offline a dead URL and no-network are indistinguishable, so the gate would either false-pass or hard-block a valid commit, and the repo bans `--no-verify`.
  - Alternative rejected: make a branch-protected CI the enforcement point. Rejected because this repo pushes straight to main with no gating CI, so a CI-only enforcement path enforces nothing; capture-time fail-closed always runs because it is how a valid lock is produced.

- Decision: `citelock capture` checks the quote against the fetched bytes and refuses to write on a miss; it records provenance (URL, timestamp, HTTP status, content hash).
  - Alternative rejected: let the author write the snapshot file directly, or check provenance only offline. Rejected because then the quote-anchor verifies the artifact against itself and an agent that authors the snapshot also authors the provenance, so the core failure mode still passes. Only a live fetch at capture sees bytes the author did not write.

- Decision: capture is static-fetch only (`curl`/`monolith`); client-side-rendered SPA sources are out of the citable set and the author cites a stable or archived URL or the underlying JSON API.
  - Alternative rejected: a headless-Chromium render path for SPA pages. Rejected because a rendered snapshot varies run to run (A/B tests, locale, consent banners), so it is a one-time capture nobody can reproduce, which readmits the "we just saved a file" hole the design forbids; it also adds a headless-browser dependency. Scoping SPAs out keeps capture reproducible and dependency-light; the cost is that the author must find a static URL for a client-rendered claim, documented in the skill.

- Decision: live-web fetches enforce an `https`-only allowlist, reject `file://`/loopback/link-local/RFC-1918, and pass every lockfile value as an inert argument.
  - Alternative rejected: fetch lockfile URLs and DOIs as-is. Rejected because a crafted field turns reviewing an untrusted change into SSRF or shell injection on the reviewer's machine.

- Decision: DOI existence and retraction are queried against the public Crossref REST API with `curl` and `jq`, cached on disk.
  - Alternative rejected: package and use `citecheck`. Rejected because `citecheck` is an MCP server, and an MCP tool fires at model discretion, so it cannot be a deterministic gate. Crossref REST is a pure request over a stable id.
  - Alternative rejected: a language-package-manager install of a DOI checker. Rejected because it is not reproducible and violates the repo's no-global-installer rule; `curl` and `jq` are already available.

- Decision: `citation-intelligence` is an optional local authoring aid, never a gate tool.
  - Alternative rejected: use it as a verification source. Rejected because it fans a query across live LLM engines and its output varies run to run.

## Rollout & Gating

Sequence, one slice per gate. Each slice is cleared by the adversarial-review loop before it is marked done.

1. Slice 1, schema delta: add the `citations.lock` rule to the `rosh-spec-driven` proposal and design instructions plus `CHANGES.md`, then `openspec schema validate rosh-spec-driven`, then `nix flake check`.
2. Slice 2, tool packaging: add `lychee`, `monolith`, and `jq` from nixpkgs, then `nix flake check`, then `nh darwin build`.
3. Slice 3, citelock verifier plus lockfile format: write `hack/citelock.sh` with the offline gate and `citelock capture` (live fetch, fail-closed re-anchor, SSRF allowlist, inert-argument passing) and the `Taskfile` entry, then `task fmt:sh:check`, then run fixtures: capture rejects a quote absent from the live bytes, a hand-authored snapshot with no provenance exits non-zero, an SSRF or `file://` target is refused, a clean fixture exits zero, and the offline gate stays green with `CITELOCK_OFFLINE=1`.
4. Slice 4, gate wiring: wire the offline stages into the flake check and pre-commit hook, then `nix flake check`, then a user smoke test that includes an offline commit and `CITELOCK_OFFLINE=1`.
5. Slice 5, skill, adversarial lens, and deterministic rubric-lint: add `citation-verification.nix` and register it, add the citation lens plus a deterministic `specreview` rubric-lint to `adversarial-review.nix` and the methodology reference, then `nix flake check`.

Gate before each `nh darwin switch`: `nix flake check` then `nh darwin build` then user spot-check. Kill switch: the pre-commit hook is the per-commit kill point and the flake check is the per-build kill point; both can be reverted per slice without touching the earlier slices.

## Risks / Trade-offs

- Risk: Crossref only surfaces a retraction on a work that has a linked retraction notice, so retraction detection is best-effort. → Mitigation: treat DOI existence as the hard check and retraction as a warning-to-fail when present; document the limitation in the skill. Maps to the Slice 3 fixture test.
- Risk: the Crossref query depends on live Crossref state, so a verdict can change over time. → Mitigation: cache results on disk; treat a transient network error as a skip-with-warning, not a fail.
- Risk: authors treat capture as busywork and paraphrase quotes. → Mitigation: the quote-anchor `grep -F` fails a paraphrase, so the gate forces a verbatim span.
- Risk: the gate blocks unrelated changes that have no external claims. → Mitigation: citelock is a no-op (exit zero) when no `citations.lock` is present and the change asserts no external-factual claims.
- Risk: a hand-authored snapshot passes the offline anchor check against itself. → Mitigation: `citelock capture` checks the quote against live bytes and fails closed, so a valid lock can only be produced by a real fetch; residual forgery by an actor who bypasses capture is out of the threat model and stated in the skill.
- Risk: reviewing an untrusted change runs attacker-chosen fetches (SSRF) or shell commands. → Mitigation: `https`-only allowlist, reject `file://`/loopback/link-local/RFC-1918, inert-argument passing; live fetches happen only at capture, never in the commit or build gate.
- Risk: no gating CI exists, so a retraction after capture is missed. → Mitigation: `citelock capture --recheck` re-runs the live checks at authoring time and fails closed; a CI re-check is optional future work, not a dependency. The offline gate stays green offline with `CITELOCK_OFFLINE=1`, so no `--no-verify` is needed.

## Adversarial Review

Rubric: the `citation-verification` spec scenarios (including the negative scenarios for a missing field, a capture that rejects a non-anchoring quote, a hand-authored snapshot without provenance, a tampered snapshot, a dead-or-retracted source at capture, an SSRF or injection target, a stale claim, a Tier 2 attempt before Tier 0 is green, and the rubric-lint catching a missing negative scenario), the `openspec-customization` delta scenarios, the `Decisions` and their rejected alternatives, the `Rollout & Gating` gate sequence, and the proposal `Non-goals`. Each slice is cleared by the `adversarial-review` loop before it is marked done: independent critics attempt to break the slice with a concrete failing scenario that names a violated rubric item, the author revises against surviving objections, and the loop repeats until no objection survives or K=4 rounds. Executor per the `adversarial-review` skill: in-process teammate critics under Claude Code, subagents elsewhere. The citation lens added in Slice 5 is itself part of the loop for later changes, and it runs only after Tier 0 is green.
