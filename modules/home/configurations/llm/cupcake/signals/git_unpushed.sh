#!/usr/bin/env bash
# Count unpushed commits on current branch
# Returns: JSON object with unpushed commit count

set -euo pipefail

# Get current branch
current_branch=$(git branch --show-current 2> /dev/null || echo "")

if [[ -z $current_branch ]]; then
  echo '{"unpushed_count": 0, "error": "not on a branch"}'
  exit 0
fi

# Count commits ahead of origin
unpushed_count=$(git rev-list --count "@{u}..HEAD" 2> /dev/null || echo "0")

# Return JSON result
echo "{\"unpushed_count\": $unpushed_count, \"branch\": \"$current_branch\"}"
