''
  # Writing a request-for-comments (RFC)

  A structure and voice guide for RFCs — documents that exist to *solicit a
  decision* from a broad audience before commitment. An RFC teaches the idea,
  specifies it precisely, surfaces what is still open, and records the
  discussion. The skill owns the section skeleton and the prose voice.

  Provenance: the section skeleton is sourced from the Rust RFC template
  (`rust-lang/rfcs`, `0000-template.md`), stripped of Rust-specific references
  (the compiler, the language, Rust teams, the rust-lang issue tracker) and tuned
  to Roshan's working voice.

  ## Decision routing

  ```
  Open question is *whether* / *which*, cross-team audience?  -> RFC (this skill)
  Direction agreed, only *how* remains?                        -> writing-doc-design instead
  Where does it land?                                           -> see Step 0
  ```

  The two share a core (Summary, Motivation, Drawbacks, alternatives). The RFC adds
  a teaching pass, prior art, open questions, and future possibilities.

  ## Step 0 — pick the destination

  ```
  if the Notion MCP is connected AND usable AND this is a work (laurel) task
    -> create the page in the private/personal portion of the Notion workspace
  elif the project is roshbhatia / ross-corp, OR Notion is unavailable
    -> write a markdown file under .sysinit/  (gitignored scratch space)
  ```

  Name local files `.sysinit/rfc-<slug>.md`. State the destination to the user
  before creating anything outward-facing.

  ## Voice — good vs bad

  Restated so the skill stands alone; `writing-tone` is the fuller reference.

  ```
  # good — teaches the idea concretely, frames the open question as a decision contract
  A user types `/share` and the doc uploads; the link is copied to the clipboard.
  Unresolved — auth model for private docs. Owner: @rosh · By: review · Done when: threat model signed off.

  # bad — abstract, hedged, no owner on the open question
  We could maybe add some kind of sharing, and there might be some auth concerns to think about.
  ```

  - **Open with scope.** What this proposes and, explicitly, what it does not (the
    Future-possibilities section carries the deliberate out-list).
  - **Pair every claim with how it is validated, and its inverse.** Especially in
    Reference-level explanation, where the design has to actually hold up.
  - **Anticipate the reader and pre-answer them** in Drawbacks and Unresolved
    questions, rather than waiting for review.
  - **Decisions are contracts.** Frame each ask as `Owner:` / `By:` / `Done when:`
    in Unresolved questions.
  - **Prose mechanics.** Terse, declarative. Backtick identifiers. Cite numbers.
    Lead with the finding. Cut hedges and preamble.
  - **Avoid:** aphorisms, named rhetorical devices, em-dashes for drama, marketing
    adjectives, throat-clearing, emojis.

  ## The skeleton

  Sections in order.

  1. **Summary** — One paragraph. The proposal in a sentence or two.
  2. **Motivation** — The problem and concrete use cases. Why now, why this is
     worth a decision. Generalized from the Rust template; no "Rust users".
  3. **Guide-level explanation** — Teach the idea *as if it already shipped*:
     examples, the mental model, how someone encounters it day to day. This pass
     is the RFC's distinctive value — if you cannot teach it cleanly, the design
     is not ready. Replace "the language / Rust" with the system or product.
  4. **Reference-level explanation** — The precise technical design: interfaces,
     interactions with existing parts, edge cases, failure modes. This is the
     spec a builder would implement from. Pair claims with validation here.
  5. **Drawbacks** — Honest reasons not to do this.
  6. **Rationale and alternatives** — Why *this* design; what other designs were
     considered and why they lose; the cost of doing nothing.
  7. **Prior art** — How others (other teams, products, languages, papers) solved
     the same problem, and what was learned. Distinct from Alternatives: prior
     art is what exists elsewhere, alternatives are designs you weighed yourself.
  8. **Unresolved questions** — What this RFC deliberately leaves open for review
     to settle, and what is out of scope for it entirely. Frame the asks as
     decision contracts.
  9. **Future possibilities** — Natural extensions noted but explicitly not in
     scope now. This is the out-list — naming it reads as a decision, not a gap.

  ## Doc frontmatter

  A trimmed version of the Rust template's header — drop the rust-lang PR and
  issue links.

  ```yaml
  title: <short imperative title>
  authors: [<name>]
  status: draft        # draft | under-review | accepted | rejected | superseded
  created: <YYYY-MM-DD>
  stakeholders: []     # who needs to weigh in
  see-also: []
  supersedes: []
  ```

  ## Template (copy-paste)

  ````markdown
  # <Title>

  > Status: draft · Authors: <name> · Created: <YYYY-MM-DD>

  ## Summary

  <One paragraph: the proposal.>

  ## Motivation

  <The problem and concrete use cases. Why now.>

  ## Guide-level explanation

  <Teach it as if it already shipped. Examples, mental model, daily use.>

  ## Reference-level explanation

  <Precise design: interfaces, interactions, edge cases, failure modes.>

  ## Drawbacks

  <Honest reasons not to do this.>

  ## Rationale and alternatives

  - Why this design: <reason>.
  - Alternative: <x> — loses because <reason>.
  - Doing nothing costs: <reason>.

  ## Prior art

  - <who/what solved this elsewhere> — takeaway: <lesson>.

  ## Unresolved questions

  - <open question> — Owner: <who> · By: <when> · Done when: <observable>.

  ## Future possibilities

  - <extension noted but out of scope now>
  ````

  ## Decision log

  RFCs accumulate discussion. Keep a running log at the bottom rather than losing
  it in comments:

  ```
  - <YYYY-MM-DD> <decision or resolved question> — <who>
  ```

  ## Checklist before sharing

  - Summary states the proposal in one paragraph.
  - Guide-level explanation teaches it without referring to the implementation.
  - Reference-level explanation is precise enough to build from.
  - Prior art and Alternatives are distinct sections, both populated.
  - Unresolved questions names what review must settle, as decision contracts.
  - At least one honest Drawback.
  - No emojis, marketing adjectives, or rhetorical flourishes.
  - Destination decided (Notion private vs `.sysinit/`) and stated.
''
