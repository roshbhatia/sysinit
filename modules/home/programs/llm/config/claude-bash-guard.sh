# PreToolUse(Bash) guard: mechanically denies the irreversible / hook-bypassing
# commands the global CLAUDE.md prohibits unconditionally, independent of the
# conversational allow/ask tiers. Reads the hook event JSON on stdin, extracts
# the bash command, and emits a structured deny decision when a prohibition is
# hit; otherwise prints nothing and exits 0 so the allow/ask tiers decide.
#
# Best-effort and fail-open: any extraction failure passes through (exit 0)
# rather than blocking. No errexit/pipefail — a non-zero grep must not turn into
# a hook abort (Claude treats exit 2 as a block).
#
# The DENY_REGEXES / DENY_REASONS tables are NOT defined here. `lib/guards.nix`
# generates them from `lib/allowlist.nix` and prepends them. Adding a pattern to
# this file would recreate the drift that made the script and the shared list
# disagree on five of six patterns.
#
# Matching is conservative and deliberately leaky at the edges. Plain `git push`
# and `git push origin main` do NOT match, because this repo permits pushing to
# main. `git -C <path> reset --hard` also does not match, because the patterns
# anchor the subcommand directly after `git`. This is a floor, not a sandbox.

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
