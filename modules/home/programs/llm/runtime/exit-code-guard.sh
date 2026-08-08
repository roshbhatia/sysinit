input="$(cat)"

out="$(printf '%s' "$input" | "$GUARD_EXE" 2> /dev/null)"

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
