input="$(cat)"

command="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2> /dev/null)"

if [ -z "$command" ]; then
  exit 0
fi

deny() {
  jq -n --arg reason "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $reason
    }
  }'
  exit 0
}

if [ "${#DENY_REGEXES[@]}" -eq 0 ]; then
  exit 0
fi

i=0
while [ "$i" -lt "${#DENY_REGEXES[@]}" ]; do
  if printf '%s' "$command" | grep -Eq "${DENY_REGEXES[$i]}"; then
    deny "${DENY_REASONS[$i]}"
  fi
  i=$((i + 1))
done

exit 0
