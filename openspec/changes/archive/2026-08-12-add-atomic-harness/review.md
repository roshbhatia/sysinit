## Rubric

- `proposal.md` `Behavior`, both the "Must do" and the "Must still hold" lists.
- `proposal.md` `Non-goals`.
- `design.md` `Decisions`, each with its `Alternative rejected:` lines.
- `design.md` `Rollout & Gating`, including the two named deviations from the
  default gate sequence.
- `design.md` `Open Questions`, which the plan deliberately leaves unsettled.
- `citations.lock`, via the `citation-verification` skill's Tier 0 gate.

An objection that cites none of these is out of scope and is discarded.

## Deterministic lint

Run 2026-08-10, before any critic.

| Check | Result |
| --- | --- |
| `specutil check --change add-atomic-harness` | 1 error: `review-decision-current`, expected until the owner records a decision below. No other rule failed. |
| `citelock verify openspec/changes/add-atomic-harness` | pass, offline gate, 8 records |
| `spec-preflight proposal` | pass on citations exists, valid, linked, fresh; Behavior present with 11 entries |
| `spec-preflight design` | pass, no rule failed beyond the pending review decision |
| `spec-preflight tasks` | pass, no rule failed beyond the pending review decision |
| `specutil render add-atomic-harness --as tickets` | renders every subtask whole, with `kind:confirm` extracted |

This is evidence. It is not approval.

## Recommendation

Model critique SHOULD run for this change, and it matters more here than in the
sibling change, because phase 1 edits a harness in daily use.

The first risk is the exclusion set's completeness. The plan excludes three of
19 pi packages and asserts the remaining 16 are clean. That assertion rests on
reading tool names, not on running the loader. Atomic's builtins are
`@bastani/workflows`, `@bastani/subagents`, `@bastani/mcp`,
`@bastani/web-access`, and `@bastani/intercom`, and the plan reasoned about
three of those five. `@bastani/workflows` registers a `workflow` tool and
`@bastani/mcp` registers `mcp`, and nothing in the plan checks that no remaining
pi package registers either name. `@monotykamary/pi-vcc` and
`@plannotator/pi-extension` are the two most likely to overlap, because both
register commands rather than only hooks. A critic should attack the plan's
claim that the load-time check in task 4.2 is a sufficient safety net, given
that the check runs after `nh darwin switch` rather than before it.

The second risk is the byte-comparison gate in task 1.3. The plan says pi's
rendered `settings.json` must be identical before and after the extraction. The
gate is correct for the settings file and it is silent about everything else
pi's module produces: `extensionFiles`, the theme JSON, the keybindings, the
permission-system config, and the five evaluation-time assertions. Moving the
package set out of `pi/default.nix` moves the input to
`assertContextHookOrder`, and a critic should test whether that assertion still
compares what it used to compare.

The third risk is ordering. `design.md` places the conflict check after the
switch, and reasons that no build can decide it. That reasoning is stated and it
deserves a challenge: a `nix run` of the built atomic derivation against a
scratch `ATOMIC_CODING_AGENT_DIR` might decide it before activation, which would
move the change's riskiest criterion in front of the gate rather than behind it.

Two risks a critic would NOT catch:

- Whether two pi-lineage harnesses are worth maintaining. That is task 4.4 and
  it is the owner's judgement.
- Which tag `nvfetcher` resolves. That is an open question with a named command,
  and running the command settles it faster than any critic.

Suggested lens set if the owner approves: tool-namespace-collision,
refactor-blast-radius, and gate-ordering. Three critics, fresh context,
read-only.

## Rounds

None run.

## Owner decision

Decision: not-run approved
State: NOT-RUN

2026-08-10: approved. Critics NOT-RUN at the owner's explicit direction, stated
in session. The three risks named under Recommendation stay open and unexamined;
the exclusion-set completeness risk is caught only after the switch, by task
4.2.
