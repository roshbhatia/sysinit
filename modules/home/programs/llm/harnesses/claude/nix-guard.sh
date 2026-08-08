input="$(cat)"

path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' 2> /dev/null)"

if [ -z "$path" ]; then
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

resolved="$(readlink -f "$path" 2> /dev/null)"
if [ -z "$resolved" ]; then
  resolved="$(readlink -f "$(dirname "$path")" 2> /dev/null)"
fi

if [ -z "$resolved" ]; then
  exit 0
fi

case "$resolved" in
  /nix/store/*)
    deny "$(printf '%s resolves to %s, which is Nix-managed and read-only. Edit the Nix source that generates it (under modules/), then run: nh darwin switch. Editing the store path directly is discarded on the next switch.' "$path" "$resolved")"
    ;;
esac

exit 0
