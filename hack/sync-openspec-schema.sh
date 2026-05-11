#!/usr/bin/env bash
# Detect drift between the forked rosh-spec-driven OpenSpec schema and the
# upstream spec-driven schema shipped with the installed openspec CLI.
#
# Reports per-file diffs and exits non-zero when drift is detected. Does NOT
# auto-merge. Reconcile divergences manually and record them in
# openspec/schemas/rosh-spec-driven/CHANGES.md.
#
# Usage: ./hack/sync-openspec-schema.sh

set -euo pipefail

FORK_DIR="openspec/schemas/rosh-spec-driven"
if [[ ! -d ${FORK_DIR} ]]; then
  echo "ERROR: fork directory not found at ${FORK_DIR}" >&2
  exit 2
fi

# Discover where the installed openspec ships its spec-driven schema.
WHICH_OUTPUT=$(openspec schema which spec-driven 2>&1 || true)
UPSTREAM_PATH=$(echo "${WHICH_OUTPUT}" | awk '/^Path:/ {print $2}')
if [[ -z ${UPSTREAM_PATH} ]] || [[ ! -d ${UPSTREAM_PATH} ]]; then
  echo "ERROR: could not resolve upstream spec-driven schema path" >&2
  echo "openspec schema which output:" >&2
  echo "${WHICH_OUTPUT}" >&2
  exit 2
fi

DRIFT_COUNT=0

# Compare every file the upstream ships against the fork. The fork is
# allowed to add files (e.g., CHANGES.md) without triggering drift.
while IFS= read -r -d '' upstream_file; do
  rel="${upstream_file#"${UPSTREAM_PATH}"/}"
  fork_file="${FORK_DIR}/${rel}"

  if [[ ! -f ${fork_file} ]]; then
    echo "MISSING-IN-FORK: ${rel}"
    DRIFT_COUNT=$((DRIFT_COUNT + 1))
    continue
  fi

  if ! diff -q "${upstream_file}" "${fork_file}" > /dev/null 2>&1; then
    echo "DIFFERS: ${rel}"
    diff -u "${upstream_file}" "${fork_file}" || true
    DRIFT_COUNT=$((DRIFT_COUNT + 1))
  fi
done < <(find "${UPSTREAM_PATH}" -type f -print0)

if [[ ${DRIFT_COUNT} -gt 0 ]]; then
  echo ""
  echo "Detected ${DRIFT_COUNT} divergence(s) from upstream spec-driven." >&2
  echo "Document deliberate divergences in ${FORK_DIR}/CHANGES.md;" >&2
  echo "reconcile accidental drift by editing the fork." >&2
  exit 1
fi

echo "OK: rosh-spec-driven matches upstream spec-driven byte-for-byte"
