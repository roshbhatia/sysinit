#!/usr/bin/env bash
# Check if .sysinit files are staged in git
# Returns: JSON object with staged .sysinit file count

set -euo pipefail

# Count staged files in .sysinit directory
staged_count=$(git diff --cached --name-only 2> /dev/null | grep -c '^\.sysinit/' || echo "0")

# Return JSON result
echo "{\"staged_sysinit_count\": $staged_count}"
