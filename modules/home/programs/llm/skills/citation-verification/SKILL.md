---
description: Verify external-factual claims (pricing, availability, external API behavior, cited papers) deterministically with `citelock`: pin each claim into a citations.lock against a tool-captured snapshot, so the offline gate is a pure function and `citelock capture` fails closed on a quote a live source does not state. Use when authoring a spec-driven change with external-factual claims; the schema makes an unanchored claim a default-reject.
allowed-tools: Bash(citelock:*) Read
---

Verify external-factual claims deterministically with `citelock`
(the `citelock` command). Pin each claim into a `citations.lock` and check it
against a tool-captured snapshot, so "is this source real and does it say
this" becomes an exit code, not a review opinion.

## When to use

- Authoring a spec-driven change that asserts external-factual claims:
  pricing, availability, external API behavior, or a cited paper. The schema
  makes an unanchored external-factual claim a default-reject.
- NOT for a bare version identifier a sha256 or lockfile pin already provides
  (nvfetcher `_sources`, `flake.lock`, `vendorHash`). Prose asserting a fact
  about that version's behavior or history IS in scope.

## The two tiers

Tier 0, offline gate (`citelock verify <change-dir>`): a pure function of
(artifact + `citations.lock`) — format lint, capture-provenance, quote-anchor
(`grep -F`), snapshot sha256, freshness. No network, no MCP tool. This is what
the pre-commit hook and the `citelock` flake check run. It is deterministic;
it only REPRODUCES the verdict capture recorded.

Tier 1, capture (`citelock capture <url> --id <id> --quote <text> --class
<class> [--doi <doi>]`): the truth-check. It fetches the URL live and FAILS
CLOSED unless the verbatim quote is a literal substring of the fetched bytes,
then writes the snapshot plus a provenance sidecar and runs the live-web
checks (`lychee` liveness, Crossref DOI existence and retraction). This is
where an agent hallucination — a real URL that does not state the claim — is
caught, because the quote is checked against bytes the author did not write.

## Authoring loop

1. Write the claim with a verbatim quote you can point to in the source.
2. Run `citelock capture` for it. If capture fails closed, either the quote is
   wrong (fix it) or the page is client-side-rendered (see below).
3. Repeat per claim; commit `citations.lock` and the `citations/` snapshots.
4. `citelock verify` runs offline at commit and build time.

## Rules that keep it honest

- Client-side-rendered SPA pages (some cloud pricing pages) are out of scope:
  capture does not run JS, so the quote will not anchor. Cite a stable or
  archived URL (a Wayback snapshot) or the underlying JSON API instead.
- The offline gate cannot tell a genuine capture from a hand-forged provenance
  sidecar; a determined author who bypasses `citelock capture` is out of the
  threat model. The gate defends against agent hallucination and accidental
  paraphrase, not a hostile author. State this; do not overclaim.
- `CITELOCK_OFFLINE=1` skips the live checks so a commit succeeds offline
  without `--no-verify`. Re-run `citelock recheck` when back online to catch a
  dead link or a retraction that appeared after capture.

## Finding a source to cite

Prefer the original source for each claim. Use a secondary source only when the
original is unavailable, and record that reason in the artifact.

To find a source for an assumption, use the harness's own web search and fetch
(WebSearch / WebFetch): no dedicated tool, MCP, or API key is needed. Once you
have a candidate URL, `citelock capture` pins and verifies it. Verification is
entirely keyless: lychee, the Crossref REST API, and monolith all work without
credentials. There is no LLM-engine dependency in this loop.

`citelock capture` also uses `pplx content fetch` as its second liveness
oracle when lychee declines, so an authenticated `pplx` removes a class of
false-negative capture failures on hosts that redirect heavily. Liveness still
fails closed: both oracles must decline.

When `pplx` is authenticated (see the `pplx-cli` skill), you MAY use
`pplx search web` to find candidate sources and `pplx content fetch` as the
snapshot fetcher for `citelock capture`. The quote-anchor semantics are
unchanged. When `pplx` is not authenticated, use WebSearch / WebFetch as above.
