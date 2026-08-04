# PreToolUse(exec) guard for devin.
#
# devin's hook payload uses the same keys as Claude Code (`tool_name`,
# `tool_input`, `hook_event_name`), so the shared destructive-command guard
# reads it unmodified. The blocking contract differs: Claude blocks via a JSON
# permissionDecision on exit 0, devin blocks via a non-zero exit code. This
# wrapper runs the shared guard and translates its deny decision into the exit
# code devin expects.
#
# Fail-open by construction: if the guard prints nothing — including when
# devin's exec tool names its command field something other than `command` —
# this exits 0 and the normal permission tiers decide.

input="$(cat)"

out="$(printf '%s' "$input" | claude-bash-guard 2> /dev/null)"

if [ -z "$out" ]; then
  exit 0
fi

decision="$(printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecision // empty' 2> /dev/null)"

if [ "$decision" = "deny" ]; then
  reason="$(printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecisionReason // "blocked by sysinit destructive-command guard"' 2> /dev/null)"
  printf '%s\n' "$reason" >&2
  exit 2
fi

exit 0
