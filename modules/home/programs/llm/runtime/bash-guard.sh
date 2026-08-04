# PreToolUse(Bash) guard: mechanically denies the irreversible / hook-bypassing
# commands the global CLAUDE.md prohibits unconditionally, independent of the
# conversational allow/ask tiers. Reads the hook event JSON on stdin, extracts
# the bash command, and emits a structured deny decision when a prohibition is

input="$(cat)"

command="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2> /dev/null)"

# Nothing to inspect -> let the normal tiers handle it.
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

# A missing or empty table means the generation broke. Fail open, consistent with
# the rest of the script: a guard that cannot read its own rules must not block
# the agent, and the fixtures check catches the breakage at build time.
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
