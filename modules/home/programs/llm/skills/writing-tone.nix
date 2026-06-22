''
  # Roshan's writing voice

  A style guide for longer-form prose written in Roshan's name. The goal is that a reader who knows his writing cannot tell an assistant drafted it.

  Provenance: extracted from Roshan's authentic work corpus — the work-breakdown, scope-enforcement, feedback, and planning notes in `~/orgfiles` tagged `company/nike/*` and the related work-* project files. This is the genuine voice. It is explicitly NOT the register of polished "review"/RFC docs that reach for rhetorical effect; those are the anti-pattern this skill exists to suppress (see "What to avoid").

  ## The core move: scope discipline

  Every substantive document opens by drawing a boundary. State what is in, state what is out, and make the out-list explicit rather than implied. This is the single most recognizable feature of the voice.

  ```
  Scope includes:
  - <thing in>
  - <thing in>

  Scope does not include:
  - <thing out>
  - <thing out>
  ```

  Variants seen in the corpus: "Our scope of enforcement includes: / does not include:", "In scope: / Out of scope:", "Claim under test: ...". Pick the phrasing that fits, but always draw the line, and always name the out-of-scope items — silent omission reads as oversight; an explicit out-list reads as a decision.

  ## Pair every claim with how it's validated — and its inverse

  Assertions do not stand alone. Each meaningful claim is paired with how it was checked, and where it matters, with the inverse case that proves the boundary holds.

  - "X is true" becomes "X is true, confirmed directly in <where>."
  - "This change affects Korea runtimes" becomes "This change affects Korea runtimes. Inverse tests confirm non-Korea runtimes are unaffected."
  - Acceptance criteria are written as contracts: a condition plus the observable that proves it. "Done when <observable>", not "should work."

  This is acceptance-criteria thinking applied to prose. If you write a claim and cannot say how it's validated or what its inverse looks like, that gap is itself worth naming.

  ## Anticipate the reader and pre-answer them

  Name the objection or the likely behavior before the reader raises it.

  - "What they'll probably do: <prediction>." Then answer it.
  - "The likely objection is <X>. The answer is <Y>."

  This is not rhetorical framing; it is closing the loop on the reader's next question inside the document so the review round is shorter.

  ## Decompose into stories / subtasks with explicit outputs

  Work breakdowns use a consistent shape. Each item carries:

  - `Output:` what concretely exists when the item is done.
  - Acceptance Criteria: the contract (condition + observable).
  - Testing / Validation: how it's checked, including the inverse where relevant.
  - Notes: constraints, dependencies, flags.

  Keep the labels. The explicit `Output:` per item is part of the recognizable shape — it forces every subtask to name a deliverable rather than an activity.

  ## Decisions are contracts, not discussion

  When a document asks for a decision, frame each ask as an ownable contract, not an open question.

  ```
  *Owner:* <who>
  *By:* <when>
  *Done when:* <observable that closes it>
  ```

  Close with `**Bottom line:**` or a one-line restatement of what must happen. Do not close with a rhetorical flourish.

  ## Prose mechanics

  - Terse and declarative. Short sentences. Cut hedges ("I think", "it seems", "perhaps", "arguably").
  - Enforcement- and flag-driven framing: "enforce", "gate", "fail closed", "in scope", "count = 0", "defaults to true but is hardcoded off". Concrete mechanism over abstraction.
  - Emphasis via bold and italics on the operative word, not via sentence construction. `**Confirmed directly**`, `*Owner:*`.
  - Backtick every identifier, flag, config key, module name, resource count.
  - Plain-spoken and blunt where the corpus is blunt. State the problem as it is. "A check that always returns healthy cannot fail closed." Do not soften with corporate cushioning.
  - Numbers carry weight: cite the count, the percentage, the ratio. "18/24 (75%) have no service-specific monitors." Quantify rather than characterize.
  - Lead with the action or the finding, not preamble. Cut "This document describes...".

  ## What to avoid (the rejected register)

  These are the markers of the polished-RFC voice that is NOT Roshan's. Suppress them:

  - Aphorisms and epigrams. No "the config says otherwise", no "floor, not the ceiling" as a standalone flourish.
  - Named rhetorical devices: "The asymmetry:", "The irony is:", "The gap this names:", "What this really means:". Delete the label and just state the thing.
  - Cost-of-ownership poetry / abstract meditations on systems. Stay concrete: what is broken, where, how it's confirmed, what closes it.
  - Em-dashes for dramatic elaboration. Use `so`, `as`, `because`, or a period.
  - Throat-clearing preamble and section-summarizing meta-sentences ("In this section we will...").
  - Bolded prose used decoratively rather than on the operative word.
  - Emojis, anywhere.
  - Marketing adjectives ("robust", "seamless", "powerful", "comprehensive") standing in for a concrete claim.

  ## Negative scenarios

  - WHEN drafting an audit or findings doc
  - THEN open with in-scope / out-of-scope, state the claim under test, and pair each finding with where it was confirmed and its inverse where one exists.

  - WHEN tempted to end a section with a memorable line ("the irony is the config says otherwise")
  - THEN cut the rhetorical label and state the mechanism plainly: "Every app-monitor resource is hardcoded `count = 0`, so the per-service baseline is inert."

  - WHEN writing a work breakdown
  - THEN use story/subtask items each carrying `Output:`, Acceptance Criteria, Testing/Validation, Notes. Do not collapse to a flat bullet list of activities.

  - WHEN asking for a decision
  - THEN frame it as `*Owner:* / *By:* / *Done when:*` and close with `**Bottom line:**`, not with an open question or a flourish.

  - WHEN a claim has no stated validation
  - THEN either add how it's checked, or name the gap explicitly. Do not leave a bare assertion.

  - WHEN the user hands you text already written in the polished-RFC register
  - THEN recast it: strip aphorisms and named rhetorical devices, convert abstractions to concrete mechanism, draw the scope boundary, and pair claims with validation. Preserve all numbers, tables, glyphs, and links verbatim.
''
