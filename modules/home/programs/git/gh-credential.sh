#!/bin/sh
# Git credential helper wrapper template.
# If GH_TOKEN is set in the environment, emit a git credential pair and exit.
# Otherwise, delegate to the gh CLI. The delegate path is substituted by Nix
# into the built helper (placeholder __GH_PATH__ below).

# Read git credential helper input until a blank line
INPUT=""
while IFS= read -r line; do
  INPUT="$INPUT$line\n"
  [ -z "$line" ] && break
done

# Try to extract host from explicit host= line, otherwise from url=
HOST=$(printf "%b" "$INPUT" | sed -n 's/^host=\(.*\)$/\1/p' | head -n1)
if [ -z "$HOST" ]; then
  URL=$(printf "%b" "$INPUT" | sed -n 's/^url=\(.*\)$/\1/p' | head -n1)
  if [ -n "$URL" ]; then
    HOST=$(printf "%s" "$URL" | sed -E 's,^[a-z]+://,,; s,.*@,,; s,/.*$,,')
  fi
fi

# If GH_TOKEN is present in the environment, use it (matching gh behaviour)
if [ -n "$GH_TOKEN" ]; then
  if [ -z "$HOST" ]; then HOST=github.com; fi
  printf 'protocol=https\n'
  printf 'host=%s\n' "$HOST"
  printf 'username=x-access-token\n'
  printf 'password=%s\n' "$GH_TOKEN"
  exit 0
fi

# Otherwise, delegate to gh's credential helper (preserve args)
exec __GH_PATH__ auth git-credential "$@"
