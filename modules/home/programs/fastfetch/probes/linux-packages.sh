#!/usr/bin/env bash
set -euo pipefail

package_count="$({ nix-store -q --requisites /run/current-system 2> /dev/null || true; } | wc -l | tr -d ' ')"
printf '%s (nix-store)' "${package_count}"
