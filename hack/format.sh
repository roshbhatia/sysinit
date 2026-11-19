#!/usr/bin/env bash
set -euo pipefail
exec nu --no-config-file "$(dirname "${BASH_SOURCE[0]}")/format.nu" "$@"
