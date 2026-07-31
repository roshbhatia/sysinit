# agent-group: the notification group name, shared by every producer and handler.
#
# Concatenated at build time (see notify.nix) into agent-notify, agent-prompt,
# and agent-focus, so the string a producer writes and the string a handler
# removes cannot drift. They did drift: agent-notify wrote
# `agent-notify:<agent>:<context>` and agent-prompt wrote
# `agent-prompt:<agent>:<context>`, while agent-focus removed only the first
# form, so an approval toast was never dismissed.
#
# Kept separate from agent-identity.sh because agent-focus needs this function
# and none of the identity resolution, which would pull in git and a wezterm
# lookup it does not use.
#
# Defines a function only; sourcing it has no side effects.

# One pane owns one notification slot, so a repeat from that pane replaces the
# pending one and any handler can rebuild the name from the pane id alone.
#
# `WEZTERM_PANE` is not forwarded over ssh, and the notifier still runs without
# it (only agent-state requires a pane). A paneless caller therefore falls back
# to the agent+context pair. Keying an empty pane id would collapse every
# paneless session onto the single group "agent:", which is worse than the
# per-agent+context keying this replaced.
#
# agent_group <agent> <context> <pane> -> the group string on stdout.
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
