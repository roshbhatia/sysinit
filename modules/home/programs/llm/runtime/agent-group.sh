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
