# Intent, feedback, and executable behavior

[Don Syme's intent and actualisation model](https://dsyme.net/2025/09/24/on-specifications-software-and-tools/)
treats elaboration as a way to narrow the possible implementations. When intent
or code changes, every retained intermediate document creates reconciliation
work. Keep the smallest description that helps the next decision. The useful
result of actualisation is behavior observed through its intended interface.

| Local phase | What to capture |
| --- | --- |
| Intent capture | The requested outcome, who needs it, the conditions that must hold, and unresolved choices that materially affect acceptance. |
| Elaboration | Current behavior, intended change, behavior to preserve, and examples with observable expected outcomes. Add a technical design when a real decision warrants one. |
| Actualisation | The implementation and the evidence obtained by running it. Record what was checked and which assumptions or cases remain open. |

## Working note

When the conversation is enough to resume or switch approaches, keep the
working material there. Otherwise, keep one note under
`${XDG_STATE_HOME:-$HOME/.local/state}/sysinit/planning/`. Use the existing
Taskwarrior UUID as the filename when available and record the local path
in that task. A note can be as short as these four lines.

```text
Context — checkout, starting revision, source ticket if any
Outcome — what needs to happen and what must still hold
Evidence — what ran, against what, and what it showed
Next — the decision, implementation step, or check that remains
```

Update entries that affect the next decision. When exiting the workflow,
preserve confirmed decisions and outstanding checks in the conversation or
existing task, wherever they will be picked up. [Extract, Edit, Apply](https://githubnext.com/projects/extract-edit-apply/)
explores the same idea of a temporary description around code that persists.

## Example of a change in scope

A request to inspect a conflicted path can begin with a single agreed
behavior: show the Git stage entries for that path while preserving the
index. Run the inspection against a real merge fixture. A three-way
conflict supplies base, ours, and theirs. An add/add conflict supplies ours
and theirs. If the user narrows the output to paths that include a base
entry, update the output criterion and recheck selection against both cases.
An index-preservation result for the unchanged command still describes
that execution. If the command changes, check preservation on the new
candidate too. Once the behavior is clear, finish in the ordinary
implementation workflow and keep the regression cases with the code.

## Close the feedback loop

[Wiener](https://mitpress.mit.edu/9780262537841/cybernetics-or-control-and-communication-in-the-animal-and-the-machine/)
frames control in terms of communication and feedback.
[Ashby's treatment of regulation](https://ashby.info/Ashby-Introduction-to-Cybernetics.pdf)
explains why a regulator needs enough responses to handle disturbances in the
conditions it aims to preserve. For this workflow, that suggests choosing
observations that distinguish relevant failures and having an appropriate
response to each, such as a code fix, another probe, or a decision about intent.

Compare observed behavior with the current acceptance criteria. A failing test
can reveal a defect, a bad assumption in the test, or an underspecified
expected outcome. Inspect the discrepancy before choosing which to change.
When the relevant intent or candidate changes, check the applicability of
earlier evidence before relying on it. Use short feedback cycles and existing
test tools. Add instrumentation when it answers a concrete unresolved question.

## Trace control flow and dependencies

For work that spans several steps, draw a small local graph with labeled
edges. Use a call or trigger edge to show how execution reaches an action, a
control-dependence edge to show which decision determines whether it runs, and
a data edge to show which state or result it reads. A dependency can matter
even when it is absent from the call graph. The
[program dependence graph](https://digitalcommons.mtu.edu/michigantech-p/12533/)
makes both control and data dependence explicit.

Apply the same idea to verification. An observation depends on the candidate
exercised and the acceptance condition it checks. When an input changes,
revisit its dependent conclusions. Preserve independent evidence that still
applies. This borrows the distinction between ordering work and deciding what
must run again from [Build Systems à la Carte](https://www.microsoft.com/en-us/research/publication/build-systems-a-la-carte/).
The feedback loop may revisit a decision. A dependency graph for one
revision can still help order its independent checks.

Start with the affected paths and reachable decisions. Use Changes and
`review-call-graph` where supported, and read the code for state ownership,
event ordering, and branches that a tool cannot infer. Use TLA+ when
interleavings matter more than a static view can show.

## Use TLA+ where order matters

[Lamport's Specifying Systems](https://lamport.azurewebsites.net/tla/book.html)
describes behavior as sequences of states and actions. When retries, delayed
results, or concurrent updates affect correctness, identify the state, what
changes it, and the invariant each reachable state must satisfy. Add a
liveness property when eventual progress matters and state the assumptions
that enable that progress.

For example, a check can start against one intent revision and return after the
intent has changed. Model the check and acceptance as separate actions. The
acceptance invariant can require evidence for the same intent and candidate
that were accepted. Test the model with and without the guard to make sure it
distinguishes that failure. In a small TLC example, ignoring the intent revision
allowed a result to arrive late and be accepted. Matching both revisions
preserved the invariant in all 79 reachable states. A finite TLC run checks
the configured model. In this example, eventual acceptance after the last
change also held under weak fairness for starting a check, receiving its
result, and accepting it. Without those assumptions, TLC found a stuttering
execution. Exercise the corresponding actions on the running
implementation to gather evidence about its behavior. Formal [refinement](https://lamport.azurewebsites.net/tla/proving-safety.pdf)
adds a separate obligation to show how a lower-level model implements a
higher-level one.

These concepts guide local work. Use the company's existing terminology and
artifact formats when communicating outcomes and evidence.
