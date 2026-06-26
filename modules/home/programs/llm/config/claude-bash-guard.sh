# PreToolUse(Bash) guard: mechanically denies the irreversible / hook-bypassing
# commands the global CLAUDE.md prohibits unconditionally, independent of the
# conversational allow/ask tiers. Reads the hook event JSON on stdin, extracts
# the bash command, and emits a structured deny decision when a prohibition is
# hit; otherwise prints nothing and exits 0 so the allow/ask tiers decide.
#
# Best-effort and fail-open: any extraction failure passes through (exit 0)
# rather than blocking. No errexit/pipefail — a non-zero grep must not turn into
# a hook abort (Claude treats exit 2 as a block).

input="$(cat)"

command="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)"

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

# Each pattern targets an unambiguous destructive / hook-bypassing form. Plain
# `git push` and `git push origin main` intentionally do NOT match -> push to
# main stays allowed (this repo permits it). Matching is conservative; the
# conversational tiers remain the catch-all for everything else.
# `--force` also covers `--force-with-lease`. The `-f` branch requires the flag
# to stand alone (surrounded by whitespace/EOL) so it never matches `--foo`.
if printf '%s' "$command" | grep -Eq 'git[[:space:]]+push\b.*([[:space:]]-f([[:space:]]|$)|--force)'; then
  deny "Force-pushing is prohibited (global CLAUDE.md: no force-push)."
fi

if printf '%s' "$command" | grep -Eq '(--no-verify|--no-gpg-sign)\b'; then
  deny "Hook-bypass flags are prohibited (global CLAUDE.md: no --no-verify / --no-gpg-sign)."
fi

if printf '%s' "$command" | grep -Eq 'git[[:space:]]+reset[[:space:]].*--hard\b'; then
  deny "git reset --hard is prohibited without explicit instruction (global CLAUDE.md)."
fi

if printf '%s' "$command" | grep -Eq 'git[[:space:]]+clean[[:space:]].*-[a-zA-Z]*f'; then
  deny "git clean -f is prohibited without explicit instruction (global CLAUDE.md)."
fi

if printf '%s' "$command" | grep -Eq 'git[[:space:]]+branch[[:space:]].*-D\b'; then
  deny "git branch -D (force-delete) is prohibited without explicit instruction (global CLAUDE.md)."
fi

if printf '%s' "$command" | grep -Eq 'git[[:space:]]+branch[[:space:]].*--delete[[:space:]].*--force\b'; then
  deny "git branch --delete --force is prohibited without explicit instruction (global CLAUDE.md)."
fi

exit 0
