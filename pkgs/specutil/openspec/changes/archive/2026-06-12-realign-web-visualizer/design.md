## Context

The web viewer's behavior is already implemented and shipped (commit
`feat(web): rework visualizer into a readable per-change document`). This change is
a **spec-realignment**: it brings the merged `web-interaction` capability in line
with the code, rather than driving new implementation. The previous spec — authored
for an interactive Cytoscape canvas with a vendored offline library — no longer
describes what the binary produces.

The redesign was the product of a deliberate UX critique and two decisive product
choices: (1) for a single change, land directly on the readable task document, only
surfacing an overview/cards/cross-change DAG when 2+ changes exist; (2) use the
charting library for a single per-phase progress bar, not the dependency graph
(which is drawn as static inline SVG by the binary).

## Goals / Non-Goals

**Goals:**
- The `web-interaction` spec describes the document-first, CDN-backed viewer that
  ships.
- Preserve the load-bearing invariant: the **binary** performs zero network I/O.
- Make the trust boundary explicit: the page's presentation layer is CDN-loaded but
  pinned + SRI + `crossorigin` + `onerror`, so it cannot be silently swapped and
  fails loudly offline.

**Non-Goals:**
- No new code. The implementation already exists and is tested.
- Not re-litigating the design choices themselves (single-doc-first, Chart.js for
  the per-phase bar, inline-SVG DAG) — those are settled.
- Not reconciling the `specutil-core` change's `web-visualizer` delta here; that is
  tracked as a follow-up task so the two changes don't conflict at archive time.

## Decisions

- **Realign via a new change, not by amending `specutil-core`.** The contradiction
  lives in the *merged* `web-interaction` capability (from the archived
  `interactive-visualizers` change). A dedicated change leaves a clean audit trail of
  what was dropped and why, via REMOVED requirements with Reason/Migration.
  *Alternative rejected*: editing `specutil-core`'s in-flight `web-visualizer` delta
  in place — it does not own the merged `web-interaction` requirements and would
  entangle this correction with unrelated in-progress work.
- **ADD + REMOVE rather than RENAME + MODIFY for renamed requirements.** OpenSpec
  matches MODIFIED requirements by exact header name; three requirements changed both
  name and substance. Expressing those as fresh ADDED requirements plus REMOVED
  (with Reason/Migration) is unambiguous and yields a clean merged spec without
  misnamed survivors. Only "Graceful empty and edgeless states" — whose name is still
  apt — is a true MODIFIED. *Alternative rejected*: RENAMED ops, which are unused
  elsewhere in this repo and add parser risk for no readability gain.
- **Keep the binary's no-network guarantee normative and separate.** The CDN
  relaxation applies to the rendered page only; the spec and the guard test
  (`TestNoNetworkImportsInBinary`) keep the binary pure.

## Risks / Trade-offs

- The page no longer renders its full presentation layer offline from `file://`. →
  Mitigated by the `onerror` fallback that surfaces a visible offline notice; inlined
  content (text, SVG DAG) still renders.
- A pinned CDN dependency could go stale or be yanked. → Version-pinned with SRI;
  bumping is a deliberate, reviewable edit, and `onerror` degrades loudly rather than
  executing a substituted bundle.
- The `specutil-core` `web-visualizer` delta still mandates Mermaid + full offline. →
  Tracked as an explicit follow-up task below; must be reconciled before
  `specutil-core` archives or it will re-merge the contradiction.

## Migration Plan

1. Land this change's spec deltas (this change).
2. Archive this change so the deltas merge into `openspec/specs/web-interaction/`.
3. Before `specutil-core` archives, reconcile its `web-visualizer` delta with the
   shipped behavior (separate follow-up) so the two do not conflict.

## Open Questions

- Should `web-interaction` and `specutil-core`'s `web-visualizer` ultimately be a
  single capability? They overlap. Deferred — out of scope for this realignment.
