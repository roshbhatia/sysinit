---
name: inspect-agent-traces
description: Inspect local agent activity and captured assistant replies with Traces. Use when the user asks what a specific agent session did, wants to read a conversation in Neovim, or needs structured trace output.
---

Use `traces` or `:Traces` to browse the current checkout's sessions in
Neovim. Use `traces --all` for machine-wide discovery and
`:Traces EXACT_SESSION_ID` to open a specific transcript.

For automation, use the exact native conversation ID:

```sh
traces --session "$session" --view output --format jsonl --once --color never
```

That export contains bounded assistant replies. To inspect activity spans or
other captured events, use `traces --json` with the narrowest available
session, provider, and time filters. Traces merges events from configured
sources. If a session is missing, check `traces provider list` and the
selected source before concluding that the session has no activity.

Use native harness or Atuin commands to resume a conversation. A Traces
transcript is a read surface.
