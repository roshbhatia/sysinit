---
name: review-change
description: Run a human review of a spec change and its code in the browser, then fold the result back into the change. Opens the annotated work graph and working-tree diff with `specutil web`, ingests the reviewer's exported feedback with `specutil review ingest`, and acts on the brief. Use when the user wants to review a plan, change, or diff, asks for feedback on a proposal, says "let me look at this before you build it", or asks what a reviewer said.
license: MIT
compatibility: Requires the specutil binary on PATH and a browser on the machine. No network access and no MCP server needed.
allowed-tools: Bash(specutil:*) Bash(pbpaste) Bash(git:*) Read Edit AskUserQuestion
metadata:
  author: specutil
  version: "1.0"
---

# Review a change with a human in the loop

Everything specutil renders is a projection of what you wrote. This is the one
path that goes the other way. A person annotates the change in a browser, and
their decision comes back as a document you act on.

The binary never opens a socket. The page has nowhere to post to. The loop
closes because the reviewer hands you a JSON export, not because anything
connects.

## When to run this

Run it before you start building a change, and again after you revise. A review
that predates your edits is reported as stale, never counted as approval.
Re-running is cheap and never silently blesses unread text.

## Flow

### 1. Open the page

```bash
specutil web                                # the plan only
specutil web --diff --change <name>         # the plan and the code you wrote
```

Use `--diff` once you have written code. It shows the working-tree diff, new
files included, based on the commit recorded at the last review.

Tell the user to open the change they want to review, then:

- comment on any task (the box under each task card)
- comment on any diff hunk (the box under each hunk)
- tick "request removal" for a task that should not exist
- pick a decision: Approve, Request changes, or Comment only
- press "Copy feedback", or "Download" for a file

Do not ask them to describe their feedback in chat. The page collects it in a
form you can act on precisely, keyed to specific tasks.

### 2. Ingest what they exported

From the clipboard:

```bash
pbpaste | specutil review ingest
```

From a downloaded file:

```bash
specutil review ingest ~/Downloads/specutil-feedback-<change>.json
```

Either writes `openspec/changes/<change>/specutil.review.yaml` and prints the
brief. Add `--dry-run` to read the brief without recording anything.

### 3. Act on the brief, in its order

The brief is ordered by what blocks work:

1. Requested removals. Delete those tasks from `tasks.md`. Do not start them.
2. Comments. Each names a task. Revise that task, or answer the question.
3. Code comments. Each names a file and a hunk. Change that code.
4. Changed since review. Tasks that moved after the reviewer read them.

Address every item. If you disagree with one, say so and leave it in place
rather than deleting the comment.

### 4. Report back

```bash
specutil review show <change>          # the verdict and what drifted
specutil review diff <change>          # what you changed since they looked
```

After you revise, `show` reports the decision as stale, which is correct: the
reviewer approved different text. Show them `review diff` and ask whether they
want another pass.

## Recording a decision without the browser

When the review happened somewhere else, record only the verdict:

```bash
specutil review set <change> --decision approved
specutil review set <change> --decision changes-requested --note "split phase 2"
```

Comments already in the record are retained. Pass `--clear-comments` to drop
them.

## Gating on the review

The `rosh-spec-driven` preset already gates on this. `specutil check` fails
while a change is unreviewed, is not approved, or was edited after its approval.

Retune it in `openspec/specutil.yaml` when a repository reviews differently:

```yaml
check:
  preset: rosh-spec-driven
  rules:
    - id: review-decision-current
      accept: [approved, commented]   # widen what counts
      requireRecord: false            # only check changes that were reviewed
```

Drop it entirely with `disable: [review-decision-current]`.

## Wiring it to a harness hook

`specutil check --as json` exits 1 on a violation, so it works as a stop or
pre-commit gate with no specutil-specific glue. For Claude Code, in
`.claude/settings.json`:

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [{ "type": "command", "command": "specutil check --as json" }]
      }
    ]
  }
}
```

Any harness that can run a command and read an exit code works the same way.

## Guardrails

- Never write `specutil.review.yaml` by hand. Use `review ingest` or
  `review set`, so the fingerprints match the artifacts on disk.
- Never re-record a decision on the user's behalf to clear a stale warning. The
  warning is the point: only the reviewer can approve the new text.
- Never treat a comment as done because you replied to it. It is done when the
  task changed or the user says otherwise.
- The identity in an annotation is a content hash, not a line number. Do not
  compute or edit one; pass the export through unmodified.
