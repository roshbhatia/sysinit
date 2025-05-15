#!/usr/bin/env bash
set -euo pipefail

CONFIG_PATH="${HOME}/.config/github-copilot/apps.json"
[[ ! -f "$CONFIG_PATH" ]] && exit 1

OAUTH_TOKEN=$(jq -r 'to_entries[0].value.oauth_token' "$CONFIG_PATH")
[[ -z "$OAUTH_TOKEN" || "$OAUTH_TOKEN" == "null" ]] && exit 1

COPILOT_TOKEN=$(curl -s -H "Authorization: Bearer $OAUTH_TOKEN" \
    "https://api.github.com/copilot_internal/v2/token" | jq -r '.token')
[[ -z "$COPILOT_TOKEN" || "$COPILOT_TOKEN" == "null" ]] && exit 1

echo "$COPILOT_TOKEN"
