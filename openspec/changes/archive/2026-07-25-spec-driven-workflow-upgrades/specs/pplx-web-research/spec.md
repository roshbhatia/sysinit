## ADDED Requirements

### Requirement: The pplx CLI is installed via overlay for every supported host
`overlays/pplx.nix` MUST provide `pplx` from the `perplexityai/perplexity-cli` v0.2.2 per-platform binary, with pinned SRI hashes for `aarch64-darwin`, `aarch64-linux`, and `x86_64-linux` (the repo's three hosts). It MUST select the correct asset per platform (`pplx-aarch64-apple-darwin.bin`, `pplx-aarch64-linux-gnu.bin`, `pplx-x86_64-linux-gnu.bin`) and mark it executable on PATH.

#### Scenario: pplx resolves on a supported host
- **POLARITY** positive
- **WHEN** the config is built for `aarch64-darwin`, `aarch64-linux`, or `x86_64-linux`
- **THEN** `pplx` resolves on PATH from the pinned binary for that platform

#### Scenario: An unsupported platform fails loudly
- **POLARITY** negative
- **WHEN** the overlay is evaluated for a platform outside the three supported systems
- **THEN** it throws a clear "pplx: unsupported platform" error rather than selecting a wrong-architecture binary

### Requirement: External web research is auth-conditional and never leaks internal content
A skill that needs general external web research MUST check `pplx auth` / `PERPLEXITY_API_KEY` at runtime. When authed, it uses `pplx search web` / `pplx content fetch`. When not authed, it falls back to the built-in WebSearch. Regardless of auth, internal, private, or in-repo content MUST NOT be sent to pplx.

#### Scenario: Authed external research uses pplx
- **POLARITY** positive
- **WHEN** `pplx auth` reports authenticated (or `PERPLEXITY_API_KEY` is set) AND the research target is external public information
- **THEN** the agent uses `pplx search web` / `pplx content fetch` for that research

#### Scenario: Unauthenticated research falls back, and internal content never goes to pplx
- **POLARITY** negative
- **WHEN** pplx is not authenticated, OR the target is internal/private/in-repo content
- **THEN** the agent does not call pplx: it uses WebSearch for external targets and local tools for internal targets

### Requirement: pplx can serve as the citelock capture fetcher when authed
When authenticated, `pplx content fetch` MAY be used as the snapshot fetcher for `citelock capture`, so external-factual claims are anchored against a pplx-retrieved snapshot. When not authed, `citelock capture` uses its existing fetch path. The captured quote-anchor semantics MUST be unchanged either way.

#### Scenario: Capture via pplx when authed
- **POLARITY** positive
- **WHEN** the owner is authed to pplx and captures an external claim
- **THEN** `citelock capture` may source the snapshot from `pplx content fetch` and the quote-anchor check still applies

#### Scenario: Capture path is unchanged when unauthed
- **POLARITY** negative
- **WHEN** pplx is not authenticated
- **THEN** `citelock capture` uses its existing fetcher and does not error on a missing pplx credential
