''
  # Writing a design doc

  A structure and voice guide for technical design docs — documents that describe
  *how* something will be built once the direction is broadly agreed. The skill
  owns the section skeleton and the prose voice; the author owns the content.

  Provenance: the section skeleton is sourced from the Kubernetes KEP template
  (`kubernetes/enhancements`, `keps/NNNN-kep-template`), stripped of
  Kubernetes-specific machinery (release signoff, graduation criteria, version
  skew, production-readiness questionnaire, feature gates) and tuned to Roshan's
  working voice.

  ## Decision routing

  ```
  Open question is *how*, not *whether*?          -> design doc (this skill)
  Open question is *whether* / *which*?            -> writing-doc-rfc instead
  Change small enough the PR description carries?   -> skip both
  Where does it land?                               -> see Step 0
  ```

  ## Step 0 — pick the destination

  Decide where the doc lands before writing a line:

  ```
  if the Notion MCP is connected AND usable AND this is a work (laurel) task
    -> create the page in the private/personal portion of the Notion workspace
  elif the project is roshbhatia / ross-corp, OR Notion is unavailable
    -> write a markdown file under .sysinit/  (gitignored scratch space)
  ```

  Name local files `.sysinit/design-<slug>.md`. State the destination to the user
  before creating anything outward-facing (a Notion page is outward-facing).

  ## Voice — good vs bad

  This skill restates the voice rules it depends on so it works standalone. For any
  other prose, the `writing-tone` skill is the fuller reference.

  ```
  # good — leads with the finding, claim paired with how it is validated
  The cache cuts cold-start p99 from 1.8s to 320ms, confirmed in the load test (k=500).

  # bad — throat-clearing, unvalidated marketing claim
  This document describes a robust, seamless caching layer that should improve performance.
  ```

  - **Open with scope.** Name in- and out-of-scope items explicitly — silent
    omission reads as oversight, an explicit out-list reads as a decision (the
    Goals / Non-Goals sections).
  - **Pair every claim with how it is validated, and its inverse where one exists.**
    Acceptance criteria are contracts: a condition plus the observable that proves
    it — "Done when <observable>", not "should work."
  - **Anticipate the reader and pre-answer them.** Name the likely objection before
    the reviewer raises it. This shortens the review round.
  - **Decisions are contracts.** Frame each ask as `Owner:` / `By:` / `Done when:`,
    and close with a one-line restatement of what must happen.
  - **Prose mechanics.** Terse, declarative. Cut hedges. Backtick every identifier,
    flag, config key. Cite the count, not "many." Lead with the finding.
  - **Avoid:** aphorisms, named rhetorical devices ("the irony is", "the
    asymmetry:"), em-dashes for drama, marketing adjectives ("robust", "seamless"),
    throat-clearing ("This document describes..."), emojis.

  ## The skeleton

  Sections in order. Drop a section only deliberately, and say why if its absence
  would surprise a reader.

  1. **Summary** — One paragraph. What this builds and why, readable on its own.
     Write it last; lead with the outcome.
  2. **Motivation** — The problem as it is. Concrete, not abstract.
     - **Goals** — what success looks like, as observable outcomes.
     - **Non-Goals** — the explicit out-list. The most load-bearing subsection.
  3. **Proposal** — The shape of the solution at a glance, before the detail.
     - **User stories / workflows** *(optional)* — who does what, end to end.
     - **Notes, constraints, caveats** — what bounds the design.
     - **Risks and mitigations** — what could go wrong and the answer to each.
  4. **Design Details** — The technical core: data shapes, interfaces, control
     flow, edge cases. Diagrams here earn their place (use the diagram skill).
     - **Validation** — how each claim is checked: tests, manual steps, and the
       inverse case that proves the boundary holds. Generalized from the KEP
       "Test Plan"; no unit/integration/e2e ceremony unless it fits.
     - **Rollout / migration** *(optional)* — how it ships and how it rolls back.
  5. **Drawbacks** — Honest reasons not to do this. If you cannot name one, the
     analysis is incomplete.
  6. **Alternatives** — Other designs considered and why each was rejected. This
     is where reviewers look first; treat it as load-bearing, not an appendix.
  7. **Dependencies / resources needed** *(optional)* — what this needs from
     other people or systems. Generalized from KEP "Infrastructure Needed".
  8. **Implementation history** — A lightweight changelog: created, revised,
     accepted. Append-only.

  ## Doc frontmatter

  A trimmed version of the KEP `kep.yaml` metadata — drop kep-number, SIGs,
  feature-gates, milestones, stage.

  ```yaml
  title: <short imperative title>
  authors: [<name>]
  status: draft        # draft | under-review | accepted | superseded
  created: <YYYY-MM-DD>
  reviewers: [<name>]  # optional
  see-also: []         # links to related docs
  supersedes: []       # docs this replaces
  ```

  ## Template (copy-paste)

  ````markdown
  # <Title>

  > Status: draft · Authors: <name> · Created: <YYYY-MM-DD>

  ## Summary

  <One paragraph: what this builds and why.>

  ## Motivation

  <The problem, stated concretely.>

  ### Goals

  - <observable outcome>

  ### Non-Goals

  - <explicitly out of scope>

  ## Proposal

  <The solution shape at a glance.>

  ### Notes, constraints, caveats

  - <what bounds the design>

  ### Risks and mitigations

  - Risk: <x>. Mitigation: <y>.

  ## Design Details

  <Data shapes, interfaces, control flow, edge cases.>

  ### Validation

  - <claim> — checked by <how>; inverse: <what proves the boundary>.

  ### Rollout / migration

  <How it ships and rolls back. Omit if trivial.>

  ## Drawbacks

  <Honest reasons not to do this.>

  ## Alternatives

  - <alternative> — rejected because <reason>.

  ## Dependencies / resources needed

  - <what this needs from elsewhere>

  ## Implementation history

  - <YYYY-MM-DD> created
  ````

  ## Checklist before sharing

  - Summary reads on its own, no jargon undefined.
  - Non-Goals lists at least one real exclusion.
  - Every claim in Design Details pairs with a Validation line.
  - Alternatives names what was rejected and why, not just the chosen path.
  - At least one honest Drawback.
  - No emojis, no marketing adjectives, no rhetorical flourishes.
  - Destination decided (Notion private vs `.sysinit/`) and stated.
''
