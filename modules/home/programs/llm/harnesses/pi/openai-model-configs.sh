# Regenerate the two @benvargas/pi-openai-* model maps from pi's own catalog.
#
# Both extensions ship a hardcoded model list, and both lists are stale: neither
# names gpt-5.6-terra, gpt-5.6-luna, or gpt-5.6-sol, so `low` verbosity and
# `/fast` reached none of them, including the model this host actually runs.
# Declaring the list in Nix instead trades one stale list for another and costs a
# commit every time OpenAI ships a model.
#
# pi already keeps ~/.pi/agent/models-store.json, one entry per provider with a
# `checkedAt` stamp and the model ids it discovered, so that is the source. Both
# extensions key on `provider/id` and both only act on provider `openai-codex`
# (SUPPORTED_PROVIDERS in pi-openai-verbosity, and the current model's provider
# in pi-openai-fast), so the catalog's `openai-codex.models[].id` is exactly the
# set that can matter. The upstream defaults also listed `openai/gpt-5.4`; that
# provider is absent from this host's catalog, so it is dropped rather than
# carried forward as a key nothing can match.
#
# Runs at activation. A model that shows up between switches is picked up on the
# next one.

STORE="${PI_MODELS_STORE:-$HOME/.pi/agent/models-store.json}"
EXT_DIR="${PI_EXT_DIR:-$HOME/.pi/agent/extensions}"
PROVIDER="openai-codex"

# An absent catalog means pi has never run on this machine. Both extensions write
# their own defaults on first start, which is strictly better than publishing an
# empty model list here and pinning them to nothing.
if [ ! -s "$STORE" ]; then
  exit 0
fi

ids=$(jq -r --arg p "$PROVIDER" '(.[$p].models // []) | map(.id) | .[]' "$STORE" 2> /dev/null || true)
if [ -z "$ids" ]; then
  echo "pi-openai-models: no $PROVIDER models in $STORE; left both configs alone" >&2
  exit 0
fi

# One JSON array of `openai-codex/<id>` keys, built by jq rather than by string
# concatenation so an id containing a quote cannot break the documents below.
keys=$(printf '%s\n' "$ids" | jq -R -s --arg p "$PROVIDER" \
  'split("\n") | map(select(length > 0)) | map($p + "/" + .)')

mkdir -p "$EXT_DIR"

# Validate before publishing, so a jq failure mid-pipe cannot leave a truncated
# config that the extension then reports as a parse warning on every start.
publish() {
  target="$1"
  tmp="$target.tmp.$$"
  cat > "$tmp"
  if ! jq -e . "$tmp" > /dev/null 2>&1; then
    rm -f "$tmp"
    echo "pi-openai-models: refusing to write malformed $target" >&2
    return 1
  fi
  # A store symlink from an earlier generation has to go first: mv onto it would
  # replace the link, but any reader that already resolved it keeps the old path.
  if [ -L "$target" ]; then
    rm -f "$target"
  fi
  mv -f "$tmp" "$target"
}

# Verbosity: every codex model at `low`. The extension writes this file only from
# ensureDefaultConfigFile, which returns early when it exists, and its
# `/openai-verbosity` command only takes `status`, so nothing else edits it.
printf '%s' "$keys" |
  jq '{models: (map({key: ., value: "low"}) | from_entries)}' |
  publish "$EXT_DIR/pi-openai-verbosity.json"

# Fast: replace supportedModels, preserve everything else. `active` is the
# owner's `/fast` state and the extension rewrites it whenever persistState is
# true, so it is read back rather than reset. `service_tier: priority` only goes
# out while fast mode is on, and it defaults off, so widening this list arms the
# toggle for every codex model without changing traffic on its own.
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
