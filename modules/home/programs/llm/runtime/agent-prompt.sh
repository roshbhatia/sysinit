if [ -n "${TMUX_PANE:-}" ]; then
  export AGENT_NOTIFY_PROFILE=prompt
fi
exec "$NOTIFY_EXE" "$@"
