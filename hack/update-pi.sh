#!/usr/bin/env bash
# Report drift between pinned pi packages in modules/home/programs/llm/config/pi.nix
# and their latest versions on the npm registry. Also detects orphan
# package-lock files under modules/home/programs/llm/config/locks/.
#
# Exits non-zero on any drift detected so this can gate CI / `task pi:update`.
# Does NOT modify pi.nix. When drift exists, prints the next steps to
# update each package (hash recompute, npmDepsHash via fake-hash technique,
# lockfile regeneration as needed).
#
# Usage: ./hack/update-pi.sh

set -euo pipefail

PI_NIX="modules/home/programs/llm/config/pi.nix"
LOCKS_DIR="modules/home/programs/llm/config/locks"

if [[ ! -f ${PI_NIX} ]]; then
  echo "ERROR: ${PI_NIX} not found" >&2
  exit 2
fi

# Packages we track: (npm-name, version-line-key). version-line-key is the
# leading attr name in the piPackages attrset OR the package basename used
# in pname for inline buildNpmPackage entries.
declare -a TRACKED=(
  "pi-context"
  "pi-subagents"
  "pi-readline-search"
  "pi-rtk"
  "pi-threads"
  "pi-interview"
  "pi-librarian"
  "pi-ask-user"
  "pi-tool-display"
  "pi-subdir-context"
  "pi-dcp"
  "pi-webfetch-to-markdown"
  "pi-mcp-adapter"
  "pi-acp"
  "pi-btw"
  "@benvargas/pi-openai-fast"
  "@benvargas/pi-openai-verbosity"
  "@juicesharp/rpiv-advisor"
  "taskplane"
  "@plannotator/pi-extension"
  # @gotgenes/pi-permission-system and @samfp/pi-memory dropped 2026-05-12
  # because their runtime depends on node:sqlite (Node 22+ built-in) which
  # bun (pi's runtime) does not provide. Re-add to TRACKED when reinstating.
  "@benvargas/pi-claude-code-use"
  "@firstpick/pi-extension-reverse-last"
  "@heyhuynhgiabuu/pi-diff"
)

drift_count=0

# Extract the pinned version for a given npm name. Looks for the version
# argument in `mkFetchedNpmPackage "<name>" "<version>"` or
# `mkBuiltNpmPackage "<name>" "<version>"` or `pname = "<name>"; version = "<version>";`.
pinned_version() {
  local pkg="$1"
  # mkFetchedNpmPackage / mkBuiltNpmPackage form
  local v
  v=$(grep -E "mk(Fetched|Built)NpmPackage \"${pkg}\" \"[0-9a-z.+-]+\"" "${PI_NIX}" |
    head -1 | sed -E 's/.*mk(Fetched|Built)NpmPackage "[^"]*" "([^"]+)".*/\2/')
  if [[ -n ${v} ]]; then
    echo "${v}"
    return
  fi
  # pname/version pair form (inline buildNpmPackage). Try the full name
  # first, then fall back to the basename (handles scoped packages where
  # pname uses only the basename).
  local basename="${pkg##*/}"
  v=$(awk -v pkg="${pkg}" -v base="${basename}" '
    /pname = "/ {
      match($0, /"[^"]+"/)
      attr = substr($0, RSTART+1, RLENGTH-2)
      if (attr == pkg || attr == base) found=1
      next
    }
    found && /version = "/ {
      match($0, /"[^"]+"/)
      print substr($0, RSTART+1, RLENGTH-2)
      exit
    }
  ' "${PI_NIX}")
  echo "${v}"
}

latest_version() {
  local pkg="$1"
  curl -sf "https://registry.npmjs.org/${pkg}/latest" 2> /dev/null |
    python3 -c 'import sys,json; print(json.load(sys.stdin).get("version","?"))' 2> /dev/null ||
    echo "?"
}

echo "=== Pinned vs latest ==="
for pkg in "${TRACKED[@]}"; do
  pinned=$(pinned_version "${pkg}")
  latest=$(latest_version "${pkg}")
  if [[ -z ${pinned} ]]; then
    printf "  %-40s NOT FOUND in %s\n" "${pkg}" "${PI_NIX}"
    drift_count=$((drift_count + 1))
    continue
  fi
  if [[ ${latest} == "?" ]]; then
    printf "  %-40s pinned=%s latest=unreachable\n" "${pkg}" "${pinned}"
    drift_count=$((drift_count + 1))
    continue
  fi
  if [[ ${pinned} != "${latest}" ]]; then
    printf "  %-40s pinned=%s  →  latest=%s  [STALE]\n" "${pkg}" "${pinned}" "${latest}"
    drift_count=$((drift_count + 1))
  else
    printf "  %-40s pinned=%s  [current]\n" "${pkg}" "${pinned}"
  fi
done

echo ""
echo "=== Orphan lock files ==="
# Known lock-name aliases that don't follow the npm-name pattern.
declare -A KNOWN_LOCKS=(
  ["pi-acp"]="pi-acp"
  ["pi-dcp"]="pi-dcp"
  ["pi-diff"]="@heyhuynhgiabuu/pi-diff"
  ["pi-mcp-adapter"]="pi-mcp-adapter"
  ["pi-webfetch-to-markdown"]="pi-webfetch-to-markdown"
  ["pi-permission-system"]="@gotgenes/pi-permission-system"
  ["pi-claude-code-use"]="@benvargas/pi-claude-code-use"
  ["pi-reverse-last"]="@firstpick/pi-extension-reverse-last"
  ["plannotator"]="@plannotator/pi-extension"
  ["taskplane"]="taskplane"
)
orphan_count=0
for lock in "${LOCKS_DIR}"/*.lock.json; do
  base="${lock##*/}"
  name="${base%.lock.json}"
  if [[ -z ${KNOWN_LOCKS[${name}]+x} ]]; then
    echo "  ORPHAN: ${lock}"
    orphan_count=$((orphan_count + 1))
  fi
done
if [[ ${orphan_count} -eq 0 ]]; then
  echo "  (none)"
fi
drift_count=$((drift_count + orphan_count))

echo ""
if [[ ${drift_count} -gt 0 ]]; then
  cat << 'EOF' >&2
=== Drift detected ===
To update a package:
  1. Bump version in modules/home/programs/llm/config/pi.nix
  2. Recompute src hash:
     for fetchzip (mkFetchedNpmPackage):
       url='https://registry.npmjs.org/<pkg>/-/<basename>-<ver>.tgz'
       raw=$(nix-prefetch-url --unpack "$url"); nix hash convert --hash-algo sha256 --from nix32 --to sri "$raw"
     for fetchurl (inline buildNpmPackage):
       nix store prefetch-file --json --hash-type sha256 "$url" | jq -r .hash
  3. If buildNpmPackage: regenerate lockfile
       tmp=$(mktemp -d); cd "$tmp"; curl -sf "$url" | tar xz --strip-components=1
       npm install --package-lock-only --ignore-scripts
       cp package-lock.json $REPO/modules/home/programs/llm/config/locks/<pkg>.lock.json
  4. If buildNpmPackage: harvest npmDepsHash
       set npmDepsHash to "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
       nix build .#darwinConfigurations.<host>.system --no-link 2>&1 | grep got:
       replace with the reported hash
EOF
  exit 1
fi

echo "OK: pi packages current"
