#!/usr/bin/env bash
set -uo pipefail

status=0

for file in "$@"; do
  [ -f "$file" ] || continue
  awk -v file="$file" '
    $0 == "# /// script" { inside = 1; opened = NR; next }
    inside && $0 == "# ///" { inside = 0; next }
    inside && $0 !~ /^#/ {
      printf "%s:%d: line is not a comment, so the `# /// script` block opened on line %d never closes\n", file, NR, opened
      bad = 1
      inside = 0
      next
    }
    END {
      if (inside) {
        printf "%s:%d: this `# /// script` block reaches the end of the file with no `# ///`\n", file, opened
        bad = 1
      }
      exit bad ? 1 : 0
    }
  ' "$file" || status=1
done

exit "$status"
