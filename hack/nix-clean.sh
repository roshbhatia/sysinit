#!/usr/bin/env bash
set -euo pipefail

rm -f result result-* 2> /dev/null || true
nix-collect-garbage
