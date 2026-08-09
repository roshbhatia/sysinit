#!/usr/bin/env bash

# Emit the closure baseline for one host: its drvPath, and the set of
# derivation paths its graph reaches with the root removed.
#
# Both are pure evaluation. Nothing is realized, so this runs on a CI runner
# that cannot hold a host closure: lv426 measures 17.5 GiB today and a runner
# has roughly 14 GB free. .github/workflows/check.yml says 17.9 GiB, measured
# earlier; the closure moved, the conclusion did not.
#
# The root is removed from the set because `<host>.drvpath` already records it,
# so keeping it in both files would report one difference twice.
#
# The set is NOT order-insensitive, and an earlier version of this comment
# claimed it was. Reordering a `buildEnv`'s `paths` moves that buildEnv's own
# derivation, which is an interior node, and every ancestor between it and the
# root, because input-addressed hashes propagate upward. Verified: two graphs
# differing only in `paths = [hello jq]` versus `[jq hello]` hold 572
# derivations each and differ on two, the root and the `-env.drv`. Removing the
# root leaves the other. The real graph carries the class: 20 `-env.drv` nodes
# for lv426 and 70 for arrakis.
#
# So a reorder reports a difference here, and callers must preserve order rather
# than rely on this being blind to it. The set still beats a bare drvPath
# comparison, because it names which derivations moved: only `-env.drv` nodes
# moving is a reorder, a missing package is a dropped module, and a hash cannot
# tell those apart.
#
# One blind spot follows from excluding the root: a change confined to the
# root's own env is invisible here, and `<host>.drvpath` is what covers it. That
# split is safe for these hosts because nothing a dropped module does stays in
# the root. `system-path.drv`, `home-manager-path.drv`, and
# `activation-script.drv` are all interior and all present in both baselines, so
# a package leaving `environment.systemPackages` or `home.packages` moves an
# entry in the set, not only the root.

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

# Emit basenames. This map is already keyed that way on Determinate Nix 3.17.3,
# so today this is identity. Normalizing rather than asserting is deliberate: it
# makes the output form independent of how Nix keys the map, so a future version
# that keys by absolute path produces the same file instead of prefixing all
# 7440 lines at once and failing the gate with a diff that reads as total drift.
# Root matching above normalizes the same way, so both ends absorb the change.
for path in kept:
    print(os.path.basename(path))
' "${drvpath}" > "${OUTDIR}/${HOST}.drvset"

# Attribute path first, because the two hosts take different ones and a hash
# with no attribute beside it cannot be re-derived from memory.
printf '%s\t%s\n' "${ATTR}" "${drvpath}" > "${OUTDIR}/${HOST}.drvpath"

count=$(wc -l < "${OUTDIR}/${HOST}.drvset" | tr -d ' ')
echo "==> ${HOST}: ${count} derivations, root excluded" >&2
echo "    ${OUTDIR}/${HOST}.drvpath" >&2
echo "    ${OUTDIR}/${HOST}.drvset" >&2
