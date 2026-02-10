#!/usr/bin/env bash
# Get current git branch name
# Returns: JSON object with branch name and protection status

set -euo pipefail

# Get current branch
current_branch=$(git branch --show-current 2> /dev/null || echo "")

if [[ -z $current_branch ]]; then
  echo '{"branch": null, "is_protected": false, "error": "not on a branch"}'
  exit 0
fi

# Check if branch is protected (main or master)
is_protected=false
if [[ $current_branch == "main" || $current_branch == "master" ]]; then
  is_protected=true
fi

# Return JSON result
echo "{\"branch\": \"$current_branch\", \"is_protected\": $is_protected}"
