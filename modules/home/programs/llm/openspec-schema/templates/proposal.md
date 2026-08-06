> The keywords MUST, MUST NOT, SHOULD, SHOULD NOT, and MAY in this document are
> to be interpreted as described in [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119).

## Why

<!-- Explain the motivation for this change. What problem does this solve? Why now?

     Every external-factual claim here MUST carry an inline citation reference
     to its `citations.lock` record id, written as `[cite: <id>]`. A claim in
     `Why` is the one most worth pinning: the whole change rests on it. -->


## What Changes

<!-- Describe what will change. Be specific about new capabilities, modifications, or removals. -->

### Non-goals

<!-- spec-driven rule: enumerate work explicitly NOT included.
     REQUIRED whenever the change touches more than one capability.
     Trivially-scoped single-capability changes MAY omit this block. -->

## Behavior

<!-- spec-driven rule: the acceptance criteria. Write each entry so a
     command or an observation can decide it. This is the rubric the design, the
     tasks, and the adversarial review are all checked against. Nothing here is
     promoted to a separate spec corpus. -->

Must do:
- <criterion>, decided by `<command or observation>`

Must still hold:
- <invariant>, decided by `<command or observation>`

Human-owned decision:
- <judgment that automation or model critique cannot approve>

## Impact

<!-- Affected code, APIs, dependencies, systems. Use plain labels and
     sub-bullets; the writing standard forbids opening a bullet with a bolded
     term, and `specutil check` enforces it. -->

Modified code:
- `<path>`

Dependencies: <!-- new or changed dependencies, or "none" -->

Impactful and irreversible actions:
<!-- spec-driven rule: enumerate every action that mutates shared state, is
     hard to reverse, or needs owner confirmation. Each becomes a verify/apply/
     confirm triad in tasks.md. Write "none" if there are none. -->

Gating signal: <!-- the feature flag, config toggle, or build-then-switch
                    sequence that scopes the rollout -->
