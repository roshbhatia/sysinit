# Maps a harness notification to one of approval, idle, or done.
#
# Prints the effective reason and returns 0 when it classifies. Returns 1 for a
# type this repo never acts on, and 2 when the type is absent and the message
# text matches nothing. The two callers diverge on 1 and 2: agent-notify
# suppresses both, agent-prompt sends a plain notification on 1 and carries the
# original reason on 2. That divergence is why this returns rather than decides.
agent_classify() {
  ac_reason=$1
  ac_type=$2
  ac_msg=$3

  if [ "$ac_reason" != "attention" ]; then
    printf '%s' "$ac_reason"
    return 0
  fi

  case "$ac_type" in
    permission_prompt | agent_needs_input)
      printf 'approval'
      return 0
      ;;
    idle_prompt)
      printf 'idle'
      return 0
      ;;
    agent_completed)
      printf 'done'
      return 0
      ;;
    auth_success | elicitation_complete | elicitation_response) return 1 ;;
    "")
      case "$ac_msg" in
        *[Pp]ermission* | *[Aa]pprov* | *[Cc]onfirm*)
          printf 'approval'
          return 0
          ;;
        *idle* | *[Ww]aiting* | *[Ii]nput*)
          printf 'idle'
          return 0
          ;;
        *)
          printf '%s' "$ac_reason"
          return 2
          ;;
      esac
      ;;
    *) return 1 ;;
  esac
}
