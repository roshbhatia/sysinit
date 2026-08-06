## Voice

Load the `writing-tone` skill for the full voice contract; it is not restated
here. The rules that bind hardest in a doc: open with an explicit in/out
scope list; pair every claim with how it is validated, and its inverse where
one exists; frame decision asks as `Owner:` / `By:` / `Done when:`; cut
hedges, marketing adjectives, throat-clearing, rhetorical devices, and emojis.

## Normative keywords (RFC 2119)

Design docs and RFCs carry requirements, so they MUST use
[RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119) keywords for every
normative statement, and MUST declare that near the top:

```
> The keywords MUST, MUST NOT, SHOULD, SHOULD NOT, and MAY in this document are
> to be interpreted as described in [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119).
```

This is the mechanism that replaces bolded emphasis. Where an earlier draft
would have written `**Required:**` or bolded a whole sentence to signal force,
write the requirement with the keyword instead and leave the prose unbolded.

- MUST / MUST NOT for an absolute requirement or prohibition. Reserve these for
  things that break the design if violated, not for strong preferences.
- SHOULD / SHOULD NOT for a requirement with legitimate exceptions. Name the
  exception where you know it.
- MAY for a genuine option, including options you are not taking. `MAY` on a
  rejected-but-viable path reads as a decision rather than an oversight.

Uppercase the keyword only when it carries normative force. Ordinary uses of
"must" and "should" in explanatory prose stay lowercase, so a reader can scan
for the uppercase ones and find every requirement.

This section applies to design docs and RFCs only. It does NOT apply to PR
descriptions, commit messages, status posts, review comments, or code comments.
