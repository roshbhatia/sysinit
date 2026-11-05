---
name: untangle-codebase
description: Diagnose and reduce structural coupling in a codebase or named subsystem. Use for an explicit untangling or architectural refactoring request, with evidence, incremental changes, and cited pattern tradeoffs.
---

# Untangle a codebase

Make code that changes together easier to change together. Reduce dependencies
between code that changes for different reasons. Preserve observable behavior
unless the user also requested a behavior change.

## Establish scope and evidence

Use the user's named area and intended outcome. An analysis request produces
findings; an implementation request authorizes the corresponding refactor.
Do not turn a local cleanup into a whole-repository rewrite. Resolve a missing
scope decision only when it materially changes the work.

Read repository guidance, active changes, and the affected entry points. Record
the existing checks and any baseline failures before changing code. Trace at
least one representative operation through callers, state, persistence, and
external dependencies as applicable. Use structural outlines and call graphs
when available; check runtime registration, configuration, generated code, and
dynamic loading before declaring a symbol unused. Git history can support a
change-coupling hypothesis, but co-change alone does not establish ownership.

Use the installed tools rather than reconstructing their analysis manually:

- Load `search-code-routing` to choose the search surface. Use `ast-grep outline`
  to map declarations, ast-grep patterns for code shapes, and `rg` for literal
  names, configuration, and prose. Read the `ast-grep-outline` or `ast-grep` skill
  for the installed command syntax.
- Load `calldiff` when caller relationships or their before/after changes matter.
  A declaration outline does not establish call edges. Check dynamic edges
  against registrations and representative runtime behavior.
- For a structural replacement spanning several sites, use ast-grep's rewrite
  preview, inspect every match, then apply the reviewed rewrite. Run the
  repository's ast-grep rules and declared language checks afterward.

Use an equivalent supported tool when a language is unsupported or a tool is
unavailable, and report the resulting coverage limit. Do not add a dependency
or generate a second analysis framework merely to follow this workflow.

## Find structural problems

For each candidate, ask which requirement makes these pieces change together.
Record concrete paths and symbols, an observed consequence or realistic change
scenario, and whether the diagnosis is observed or inferred.

- Hidden coupling: duplicated authoritative values, implicit ordering, shared
  mutable state, or a feature whose ownership is obscured across modules.
- Unnecessary coupling: callers using implementation details, workflow-specific
  vocabulary leaking into shared code, or a stable policy tied to a volatile
  integration.
- Surplus structure: unused code, pass-through layers without a boundary role,
  or extension mechanisms with no supported variation.

Treat retries, sleeps, compatibility branches, swallowed errors, disabled tests,
and one-caller parameters as investigation leads. They can encode real latency,
failure, compatibility, or product requirements. Establish that requirement
before removing them. A wrapper can own translation or compatibility even when
it is small. Repeated syntax does not establish shared domain meaning.

## Choose a design with sources

Group findings that share a cause. Prefer the smallest change that removes that
cause within scope. Compare keeping the current design, a direct local fix, and
a named pattern only when the pattern adds value. Read the relevant entries in
[pattern references](references/patterns.md), rather than importing a catalog
into every task.

For a proposed pattern, state:

1. The concrete problem and code evidence it addresses.
2. The source's problem statement, applicability, and tradeoffs, with a direct
   link to the entry actually read.
3. How the proposal maps to this code, what remains different, and why a simpler
   change is insufficient.
4. Added interfaces, state, deployment or operational cost, and a behavior check
   that will demonstrate the intended improvement.

Distinguish an existing pattern observed in the code from a proposed one.
Use Martin Fowler's enterprise application patterns and refactoring catalog for
application boundaries and small transformations. Use Microsoft's Azure pattern
catalog when the problem involves distributed systems, integration, or gradual
migration. The Azure examples do not require adopting Azure services. Attribute
patterns to the source consulted; Fowler's catalogs do not make him the author
of every design pattern.

Read primary sources before citing them. Attach each citation to the claim it
supports. If a source is unavailable, mark the pattern mapping unverified and
ground the local recommendation in code evidence. Do not invent quotations,
page numbers, performance gains, or certainty about pattern fit.

## Implement and verify in increments

Keep a decision log for work spanning multiple changes. Group each chosen fix
with the findings it resolves, touched boundaries, verification, and remaining
questions. Use an existing task artifact or ignored scratch location unless a
tracked document is requested.

Make independently checkable changes. Preserve APIs, serialization, ordering,
error behavior, and operational constraints unless changing them is in scope.
Use characterization tests where behavior is unclear. Test the production path
and relevant failure cases. Compare dependencies and representative change paths
before and after the refactor; fewer files or fewer conditionals alone do not
prove an improvement.

Keep comment and test cleanup tied to changed code. Preserve requirement,
compatibility, and workaround explanations while their constraints still apply.
Rewrite tests coupled to internals around observable behavior; remove a test
only after establishing that its regression protection is redundant or invalid.
Report discovered bugs separately unless their fix is already authorized.

Review the full diff for remaining hidden coupling and unjustified abstractions.
Use independent review only when available and authorized. Finish when the
in-scope findings are resolved or explicitly deferred, checks pass or their
limits are reported, and representative behavior is preserved. Do not repeat
until an entire repository has no conceivable improvement left.

Return the changes or findings, code evidence, design decisions with source
links, checks actually run, and remaining constraints or deferred work.

## Provenance

Adapted from [caldoai/skills, untangle-codebase at f3cf477](https://github.com/caldoai/skills/blob/f3cf47774975a7d9fca45730babf4ff7ad765ada/skills/untangle-codebase/SKILL.md).
This local adaptation adds bounded scope, behavior verification, and primary
source pattern evaluation. The upstream license is retained in
[LICENSE](references/LICENSE).
