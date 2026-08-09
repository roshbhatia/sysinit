#!/usr/bin/env bash

# Emit the closure baseline for one host: its drvPath, and the set of
# derivation paths its graph reaches with the root removed.
#
# Both are pure evaluation. Nothing is realized, so this runs on a CI runner
# that cannot hold a host closure: lv426 measures 17.5 GiB and a runner has
# roughly 14 GB free (see .github/workflows/check.yml).
#
# The root is removed because it is the one derivation a reordering rewrite
# moves. `buildEnv` with [hello jq] and with [jq hello] installs the same
# packages and yields different root hashes, so a gate that kept the root would
# fail on a correct implementation. Every other path in the graph is unchanged
# by order, which makes the remaining set the thing worth comparing.

set -euo pipefail

usage() {
  echo "usage: ${0##*/} <lv426|arrakis> <outdir>" >&2
  exit 2
}

[[ $# -eq 2 ]] || usage

HOST="$1"
OUTDIR="$2"

case "${HOST}" in
  lv426) ATTR=".#darwinConfigurations.lv426.system" ;;
  arrakis) ATTR=".#nixosConfigurations.arrakis.config.system.build.toplevel" ;;
  *)
    echo "ERROR: unknown host '${HOST}'; hosts/default.nix defines lv426 and arrakis" >&2
    exit 2
    ;;
esac

mkdir -p "${OUTDIR}"

echo "==> ${HOST}: evaluating ${ATTR}" >&2
drvpath=$(nix eval --raw "${ATTR}.drvPath")

echo "==> ${HOST}: enumerating the derivation graph" >&2
# shellcheck disable=SC2016 # the single quotes hold python, not shell
nix derivation show -r "${ATTR}" |
  python3 -c '
import json, os, sys

# Compare basenames. Determinate Nix 3.17.3 keys this map by store-path
# basename while `nix eval .drvPath` returns an absolute path, so matching the
# two verbatim finds nothing and removes nothing. That failed silently: the
# count came back identical to the full graph and read as success.
root = os.path.basename(sys.argv[1])
graph = json.load(sys.stdin)["derivations"]
kept = sorted(p for p in graph if os.path.basename(p) != root)

if len(kept) != len(graph) - 1:
    print(
        "ERROR: expected to drop exactly the root derivation, dropped "
        f"{len(graph) - len(kept)}. Root: {root}",
        file=sys.stderr,
    )
    sys.exit(1)

for path in kept:
    print(path)
' "${drvpath}" > "${OUTDIR}/${HOST}.drvset"

# Attribute path first, because the two hosts take different ones and a hash
# with no attribute beside it cannot be re-derived from memory.
printf '%s\t%s\n' "${ATTR}" "${drvpath}" > "${OUTDIR}/${HOST}.drvpath"

count=$(wc -l < "${OUTDIR}/${HOST}.drvset" | tr -d ' ')
echo "==> ${HOST}: ${count} derivations, root excluded" >&2
echo "    ${OUTDIR}/${HOST}.drvpath" >&2
echo "    ${OUTDIR}/${HOST}.drvset" >&2
