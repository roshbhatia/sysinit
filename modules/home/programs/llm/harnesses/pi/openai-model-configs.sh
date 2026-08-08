STORE="${PI_MODELS_STORE:-$HOME/.pi/agent/models-store.json}"
EXT_DIR="${PI_EXT_DIR:-$HOME/.pi/agent/extensions}"
PROVIDER="openai-codex"

if [ ! -s "$STORE" ]; then
  exit 0
fi

ids=$(jq -r --arg p "$PROVIDER" '(.[$p].models // []) | map(.id) | .[]' "$STORE" 2> /dev/null || true)
if [ -z "$ids" ]; then
  echo "pi-openai-models: no $PROVIDER models in $STORE; left both configs alone" >&2
  exit 0
fi

keys=$(printf '%s\n' "$ids" | jq -R -s --arg p "$PROVIDER" \
  'split("\n") | map(select(length > 0)) | map($p + "/" + .)')

mkdir -p "$EXT_DIR"

publish() {
  target="$1"
  tmp="$target.tmp.$$"
  cat > "$tmp"
  if ! jq -e . "$tmp" > /dev/null 2>&1; then
    rm -f "$tmp"
    echo "pi-openai-models: refusing to write malformed $target" >&2
    return 1
  fi
  if [ -L "$target" ]; then
    rm -f "$target"
  fi
  mv -f "$tmp" "$target"
}

printf '%s' "$keys" |
  jq '{models: (map({key: ., value: "low"}) | from_entries)}' |
  publish "$EXT_DIR/pi-openai-verbosity.json"

FAST="$EXT_DIR/pi-openai-fast.json"
existing='{}'
if [ -s "$FAST" ] && jq -e . "$FAST" > /dev/null 2>&1; then
  existing=$(cat "$FAST")
fi
printf '%s' "$existing" |
  jq --argjson keys "$keys" '
    .persistState = (.persistState // true)
    | .active = (.active // false)
    | .supportedModels = $keys
  ' |
  publish "$FAST"
