# shellcheck shell=bash
send_now_tools=${send_now_tools:-[]}
schedule_tools=${schedule_tools:-[]}
allowed_channels=${allowed_channels:-[]}

input=$(cat)
tool=$(jq -r '.tool_name // empty' <<< "$input" 2> /dev/null)

if jq -e --arg tool "$tool" 'index($tool) != null' <<< "$send_now_tools" > /dev/null; then
  channel=$(jq -r '.tool_input.channel_id // empty' <<< "$input" 2> /dev/null)
  if jq -e --arg channel "$channel" 'index($channel) != null' <<< "$allowed_channels" > /dev/null; then
    exit 0
  fi
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: "Slack sends are gated to skill-approved channels. This destination is not in the allow-list."
    }
  }'
elif jq -e --arg tool "$tool" 'index($tool) != null' <<< "$schedule_tools" > /dev/null; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: "Scheduled Slack sends are always blocked."
    }
  }'
fi

exit 0
