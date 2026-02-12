#!/bin/bash
# SysinitSpec /plan command - Creates OpenSpec PRD and initializes beads if needed
# Usage: plan.sh <feature-name> [worktree-path]

set -e

FEATURE_NAME="$1"
WORKTREE="${2:-$(pwd)}"

if [ -z "$FEATURE_NAME" ]; then
  echo "Usage: plan.sh <feature-name>"
  echo "Example: plan.sh user-authentication"
  exit 1
fi

# Check if beads is initialized, init if not
BEADS_DIR="$WORKTREE/.beads"
if [ ! -d "$BEADS_DIR" ]; then
  echo "Beads not initialized, running bd init..."
  bd init
  echo "Beads initialized successfully"
fi

# Create OpenSpec feature
echo "Creating OpenSpec feature: $FEATURE_NAME"
openspec create-feature "$FEATURE_NAME" --template standard

SPEC_PATH="$WORKTREE/.openspec/features/$FEATURE_NAME/spec.md"

if [ -f "$SPEC_PATH" ]; then
  echo "Created PRD at: $SPEC_PATH"
  echo "$SPEC_PATH"
else
  echo "Error: Failed to create PRD"
  exit 1
fi
