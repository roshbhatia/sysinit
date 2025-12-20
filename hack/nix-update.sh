#!/usr/bin/env bash
set -euo pipefail

nix flake update

if ! git diff --quiet flake.lock; then
  git add flake.lock
  git commit -m "flake.lock: Update"
fi
