# Review across harnesses

## Managed judged pass

The managed Claude Code configuration connects the gate's Agent/Task
pre- and post-tool handlers and SubagentStart. It publishes
`review-mediator` with read-only tools. Check that the active session exposes
the configured critic type (normally `Explore`) and `review-mediator`, and
that the hooks are enabled. Restricted or headless sessions can omit those
surfaces. Inspect `review policy` for eligible roles and caps. This command
reads policy without establishing that hooks ran.

Use foreground calls in the reviewed checkout so the completion hook can
record evidence for the pass. The Gate integration can require registered
critic completions and mediation before judging. Check the installed
version and confirm the recorded evidence. The coordinator checks that each
critic returned usable evidence. The mediator returns its
JSON in its response. The coordinator writes the pass file using its
authorized tools and runs `review judge`. Keep shell and file writers out
of the mediator. The judge checks whether the evidence can be anchored.
It cannot establish whether the scenario is true.

## Ordinary review

Use one local inspection pass for an ordinary review. Give an authorized
independent helper a narrow, read-only question only when separation adds
value. Verify the actual tool permissions and distinguish a separate
context from a separate checkout.

- Codex supports native review and bounded exploration. The managed
  Codex edit guard does not provide the judged-pass roles and routing.
- Copilot CLI offers separate-context custom agents. Its managed guard is
  not the Claude review integration.
- OpenCode supports subagents with their own effective permissions. A role
  named `review-mediator` alone does not provide the ledger gate.
- Antigravity's subagent and plan controls depend on the active client
  surface. A headless plan can establish routing intent. It does not
  establish that the managed judged pass is available.

Sources for native capabilities are the [Claude Code subagents guide](https://code.claude.com/docs/en/sub-agents),
[GitHub Copilot CLI custom agents](https://docs.github.com/en/copilot/how-tos/copilot-cli/use-copilot-cli/invoke-custom-agents),
[OpenCode permissions](https://opencode.ai/docs/permissions/), and
[Antigravity CLI subagents](https://antigravity.google/docs/subagents?tab=cli).
