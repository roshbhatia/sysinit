#!/usr/bin/env bash
set -euo pipefail

printf '%s\n' "${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-unknown}}"
