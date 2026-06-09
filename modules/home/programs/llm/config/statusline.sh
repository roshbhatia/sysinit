# Claude Code statusline. Reads the session JSON on stdin and prints a single
# line: model, context use, git branch, and — when relevant — the active seshy
# session and openspec change.
#
# Best-effort by design: no `set -e`, every segment is guarded so one failure
# (not a git repo, no openspec, no seshy) never blanks the whole line.

input=$(cat)

model=$(printf '%s' "$input" | jq -r '.model.display_name // empty')
dir=$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd // empty')
pct=$(printf '%s' "$input" | jq -r '.context_window.used_percentage // empty' | cut -d. -f1)

parts=()
[ -n "$model" ] && parts+=("$model")
[ -n "$pct" ] && parts+=("${pct}% ctx")

if [ -n "$dir" ]; then
  branch=$(git -C "$dir" branch --show-current 2> /dev/null)
  [ -n "$branch" ] && parts+=("git:$branch")
fi

# seshy stores sessions under this dir; the active session is the first path
# component of cwd beneath it.
sessions_dir="$HOME/.local/state/seshy/sessions"
if [ -n "$dir" ] && [ "${dir#"$sessions_dir"/}" != "$dir" ]; then
  session=${dir#"$sessions_dir"/}
  session=${session%%/*}
  [ -n "$session" ] && parts+=("seshy:$session")
fi

# openspec: walk up to the project root, then surface the active change.
# Newest-by-mtime mirrors /opsx:apply's "most recent" inference; the archive
# dir is excluded.
osroot="$dir"
while [ -n "$osroot" ] && [ "$osroot" != "/" ]; do
  [ -f "$osroot/openspec/config.yaml" ] && break
  osroot=${osroot%/*}
done
changes_dir="$osroot/openspec/changes"
if [ -n "$osroot" ] && [ -d "$changes_dir" ]; then
  active=$(ls -1t "$changes_dir" 2> /dev/null | grep -v '^archive$' | head -1)
  count=$(ls -1t "$changes_dir" 2> /dev/null | grep -vc '^archive$')
  if [ -n "$active" ]; then
    if [ "${count:-1}" -gt 1 ]; then
      parts+=("openspec:$active +$((count - 1))")
    else
      parts+=("openspec:$active")
    fi
  fi
fi

out=""
for p in "${parts[@]}"; do
  if [ -z "$out" ]; then
    out="$p"
  else
    out="$out · $p"
  fi
done
printf '%s' "$out"
