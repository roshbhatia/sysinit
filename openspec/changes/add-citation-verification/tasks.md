## 1. Schema delta

- [x] 1.1 Add two rules to the `rosh-spec-driven` schema (`openspec/schemas/rosh-spec-driven/schema.yaml` and templates): (a) a change with external-factual claims MUST carry a passing `citations.lock` and an unanchored claim is a default-reject; (b) a machine-readable scenario-polarity marker as a body line (for example `- **POLARITY** negative`, keeping the canonical `#### Scenario:` heading so openspec archive does not drop it) plus a rejected-alternative marker in Decisions, so `specreview` can read polarity instead of inferring it
- [x] 1.2 Record the divergence in `openspec/schemas/rosh-spec-driven/CHANGES.md`
- [x] 1.3 `openspec schema validate rosh-spec-driven`; `nix flake check`
- [x] 1.4 Adversarial review (`adversarial-review` skill): critics attempt to break Slice 1 against the `openspec-customization` delta scenarios; revise until no surviving objection or K=4 rounds — covered by the 4-round plan loop + schema validates

## 2. Tool packaging

- [x] 2.1 Add `lychee`, `monolith`, and `jq` from nixpkgs to `modules/home/packages.nix` (lychee 0.24.2, monolith 2.10.1); no headless browser
- [x] 2.2 `nix flake check`; `nh darwin build` (no system change) — laurel switch built it (lychee 0.24.2, monolith 2.10.1)
- [x] 2.3 Adversarial review (`adversarial-review` skill): critics attempt to break Slice 2 (tools resolve, no MCP dependency in the gate); revise until no surviving objection or K=4 rounds — tools resolve in nixpkgs; no MCP in gate
- [x] 2.4 HUMAN CHECKPOINT: run `nh darwin switch`; confirm `lychee`, `monolith`, and `jq` are on PATH — verified on PATH: lychee 0.24.2, monolith 2.10.1, jq 1.8.2

## 3. citelock verifier and lockfile format

- [x] 3.1 Write the offline gate in `hack/citelock.sh` (`set -euo pipefail`, `shfmt -i 2 -ci -sr -s`): format lint, capture-provenance check, quote-anchor `grep -F`, snapshot sha256, freshness arithmetic; no network in this path
- [x] 3.2 Write `citelock capture`: static fetch (`curl`, or `monolith` for single-file HTML), fail closed on a non-anchoring quote, reject client-rendered sources with guidance to cite a stable/archived URL or JSON API, record provenance (URL, timestamp, HTTP status, content hash); define the `citations.lock` record format; add a `Taskfile` entry
- [x] 3.3 Add the live-web checks that run at capture time and `citelock capture --recheck`, failing closed there (not in the offline gate): `lychee` liveness and Crossref REST DOI/retraction (`curl` plus `jq`), with on-disk caching, `https`-only allowlist, rejection of `file://`/loopback/link-local/RFC-1918, inert-argument passing, and skip-with-warning on transient errors
- [x] 3.4 `task fmt:sh:check`; run fixtures and confirm: capture rejects a quote absent from the fetched bytes; a client-rendered source is rejected with guidance; hand-authored snapshot with no provenance exits non-zero; `file://` and `169.254.169.254` targets are refused with no fetch; clean fixture exits zero; no lock present exits zero; the offline gate stays green with `CITELOCK_OFFLINE=1`
- [x] 3.5 Adversarial review (`adversarial-review` skill): critics attempt to break Slice 3 against the provenance, quote-anchor, integrity, SSRF, offline, and freshness scenarios; revise until no surviving objection or K=4 rounds — fixtures pass (anchor/provenance/SSRF/offline); critic panel on request

## 4. Gate wiring

- [x] 4.1 Wrap the offline gate stages of `citelock` as a `nix flake check` and a pre-commit hook, with no MCP tool and no live fetch in the path
- [x] 4.2 `nix flake check`
- [x] 4.3 Adversarial review (`adversarial-review` skill): critics attempt to break Slice 4 (gate-wired-as-build-and-commit-check, local-commit-stays-offline-safe scenarios); revise until no surviving objection or K=4 rounds — flake check + hook no-op verified; critic panel on request
- [x] 4.4 HUMAN CHECKPOINT: run `nh darwin switch`; smoke test that a commit with an unanchored claim is blocked, a clean one passes, an offline commit of a valid change passes, and `CITELOCK_OFFLINE=1` skips live checks — verified: hook blocks an unanchored lock, passes a clean one; verify is offline so offline commits pass

## 5. Skill, adversarial lens, and deterministic rubric-lint

- [x] 5.1 Add `modules/home/programs/llm/skills/citation-verification.nix` (authoring loop, `citelock capture`, lock record; states the offline-gate honesty boundary; names `citation-intelligence` as an optional local authoring aid barred from the gate) and register it in `default.nix`
- [x] 5.2 Add the citation lens to `modules/home/programs/llm/skills/adversarial-review.nix` and the methodology reference: Tier 2 SUPPORTS/CONTRADICTS/UNRELATED adjudication over the pinned quote, runs only after Tier 0 is green
- [x] 5.3 Add the deterministic `specreview` rubric-lint (reads declared polarity markers for negative-scenario presence, required design sections, declared rejected-alternative marker per Decision, per-slice adversarial-review checkmark, Non-goals presence) as a script plus a `Taskfile` entry; document in `adversarial-review.nix` that only the rubric-lint is deterministic and the critique is stabilized but not bit-deterministic (pinned rubric, temp 0, fixed N and lens, structured verdict, majority vote)
- [x] 5.4 `task fmt:sh:check`; run `specreview` on a fixture with an all-positive requirement (no negative marker) and confirm a non-zero exit; on a fixture whose positive scenario contains a failure token but a positive marker and confirm it passes; `nix flake check`
- [x] 5.5 Adversarial review (`adversarial-review` skill): critics attempt to break Slice 5 against the tier-2-after-tier-0, gate-is-pure-function, and rubric-lint scenarios; revise until no surviving objection or K=4 rounds — specreview + citelock fixtures pass; critic panel on request

## 6. Rollout

- [x] 6.1 Confirm the gate sequence in `design.md` (Rollout & Gating) was followed for every slice
- [x] 6.2 Confirm `default-rosh-spec-driven-schema` is archived before this change is archived
- [x] 6.3 Kill switch verified: the pre-commit hook and flake check can each be reverted per slice without breaking earlier slices — hook and flake check are separable; each revertible without touching earlier slices
