---
name: pr-walkthrough
description: Walk a reviewer through a pull request or branch using the changed entry points, ownership boundaries, data flow, and a suggested reading order. Use when explicitly asked for a PR walkthrough or an orientation map.
metadata: {"sysinit-claude-disable-model-invocation":"true"}
---

# PR walkthrough

1. Resolve the exact base and head from Git or PR metadata. Use the matching
   checkout, then load `review-change-groups` and read the changed code plus the
   relevant callers and downstream owners. Use `review-call-graph` for a
   supported language when call edges matter.
2. Explain the affected behavior, the entry point, who owns state and decisions,
   and where the flow ends. When a graph helps, label calls, decisions that
   govern execution, and data dependencies. Use a small slice around the
   change. Include the smallest reading order that helps a
   reviewer understand the change. Tie important claims to the inspected head
   and focus on verification points. Use existing review comments as context
   and route a request for new findings to the review workflow.
3. Return the walkthrough in the conversation. If an interactive view is
   requested, use the available local rendering workflow and verify the result
   offline. Keep local artifacts outside tracked files and publishing flows.

<!-- include: local-planning.md -->

Adapted from [Warp's PR walkthrough](https://github.com/warpdotdev/common-skills/blob/8792394ff1b655e0af451b8fabb68ef0cfcbd208/.agents/skills/pr-walkthrough/SKILL.md).
