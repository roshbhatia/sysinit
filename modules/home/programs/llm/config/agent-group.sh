# Notification group name, shared by both producers and the click handler.
# Concatenated into agent-notify, agent-prompt, and agent-focus at build time
# (see notify.nix) so the string they write and remove cannot drift.

# agent_group <agent> <context> <pane> -> group name on stdout.
# Falls back to agent+context when the pane id is empty, as ssh does not forward
# WEZTERM_PANE and keying on "" would collapse every paneless session onto one slot.
agent_group() {
  ai_agent=${1:-agent}
  ai_context=${2:-}
  ai_pane=${3:-}
  if [ -n "$ai_pane" ]; then
    printf 'agent:%s' "$ai_pane"
  else
    printf 'agent-notify:%s:%s' "$ai_agent" "$ai_context"
  fi
}
