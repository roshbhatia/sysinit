#!/usr/bin/env bash
# Fail when a state path is written down outside the paths module.
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

token="sysinit:documented-default"

# Assembled from two halves so this file does not itself contain the string it
literal=".local""/state"

status=0

is_in_scope() {
  case "$1" in
    modules/shared/options/paths.nix | modules/shared/options/paths-layout.json)
      # The producer.
      return 1
      ;;
    *.md | openspec/*)
      # Prose. Documentation that describes a default is not a second producer
      # of one.
      return 1
      ;;
    .sysinit/*)
      # Captured upstream state, rewritten by the sync scripts.
      return 1
      ;;
    *_test.go | *_test.py | *_spec.lua)
      # Tests pin the documented default on purpose, which is what keeps the
      # fallback honest. Three of them assert it today.
      return 1
      ;;
  esac
  return 0
}

while IFS= read -r file; do
  is_in_scope "$file" || continue
  [ -f "$file" ] || continue
  grep -Iq . "$file" 2> /dev/null || continue # skip binaries

  report=$(
    awk -v token="$token" -v literal="$literal" '
      {
        # Both forms. The Go consumers never match the literal, because they
        hit = (index($0, literal) > 0) || ($0 ~ /"\.local"[[:space:]]*,[[:space:]]*"state"/)
        if (hit) {
          if (index($0, token) > 0 || index(prev, token) > 0) {
            marked++
            marked_lines = marked_lines " " FNR
          } else {
            unmarked_lines = unmarked_lines " " FNR
            unmarked++
          }
        }
        prev = $0
      }
      END {
        if (unmarked > 0) printf "unmarked:%s\n", unmarked_lines
        if (marked > 1) printf "extra:%s\n", marked_lines
      }
    ' "$file"
  )

  [ -n "$report" ] || continue
  status=1
  while IFS= read -r finding; do
    case "$finding" in
      unmarked:*)
        echo "state-paths: $file: unmarked state path at line(s)${finding#unmarked:}" >&2
        ;;
      extra:*)
        echo "state-paths: $file: more than one documented default, at line(s)${finding#extra:}" >&2
        ;;
    esac
  done <<< "$report"
done < <(git ls-files)

if [ "$status" -ne 0 ]; then
  cat >&2 << EOF
state-paths: read the path from the manifest instead of writing it down.
  shell   . paths.sh, then sysinit_path <key>
  go      internal/paths
  python  sysinit_path() in worklog-hook.py
  lua     utils.state_path(key, fallback)
  yaml    substituted at build time from config.sysinit.paths.resolved
A reader may keep one fallback for a box with no manifest. Mark it
$token on that line or the line above.
EOF
fi

exit "$status"
