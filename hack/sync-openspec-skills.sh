#!/usr/bin/env bash
# Detect drift between the locally vendored openspec-* SKILL.md bodies
# (under modules/home/programs/llm/skills/) and the upstream `openspec
# instructions <artifact>` output for the active schema.
#
# Exits non-zero when drift is detected so this can gate `task openspec:sync`
# or CI. Does NOT auto-merge.
#
# Usage: ./hack/sync-openspec-skills.sh

set -euo pipefail

SKILLS_DIR="modules/home/programs/llm/skills"
ARTIFACTS=(propose apply explore archive)
DRIFT_COUNT=0
TMP_DIR=$(mktemp -d)
trap 'rm -rf "${TMP_DIR}"' EXIT

for artifact in "${ARTIFACTS[@]}"; do
  case "${artifact}" in
    propose | apply | explore | archive) ;;
    *)
      echo "ERROR: unknown artifact '${artifact}'" >&2
      exit 2
      ;;
  esac

  local_file="${SKILLS_DIR}/openspec-${artifact}.nix"
  if [[ ! -f ${local_file} ]]; then
    echo "MISSING: ${local_file}" >&2
    DRIFT_COUNT=$((DRIFT_COUNT + 1))
    continue
  fi

  # Local body is everything between the opening '' and closing ''
  # in the Nix string literal. Strip leading/trailing '' lines.
  sed -n "2,/^''$/p" "${local_file}" | sed '$d' > "${TMP_DIR}/local.${artifact}"

  # Upstream body: pull the SKILL.md packaged with the openspec CLI for
  # this artifact (the project-local copy under sysinit/.claude/skills/ is
  # the closest stable source we have today).
  upstream_candidate=".claude/skills/openspec-${artifact}-change/SKILL.md"
  if [[ ! -f ${upstream_candidate} ]] && [[ ${artifact} == "explore" ]]; then
    upstream_candidate=".claude/skills/openspec-explore/SKILL.md"
  fi
  if [[ ! -f ${upstream_candidate} ]] && [[ ${artifact} == "propose" ]]; then
    upstream_candidate=".claude/skills/openspec-propose/SKILL.md"
  fi
  if [[ ! -f ${upstream_candidate} ]]; then
    echo "INFO: no upstream reference for openspec-${artifact}; skipping" >&2
    continue
  fi

  # Strip upstream frontmatter (everything up to and including the second '---')
  awk '/^---$/{c++; next} c>=2' "${upstream_candidate}" > "${TMP_DIR}/upstream.${artifact}"

  if ! diff -q "${TMP_DIR}/upstream.${artifact}" "${TMP_DIR}/local.${artifact}" > /dev/null 2>&1; then
    echo "DRIFT: openspec-${artifact}"
    diff -u "${TMP_DIR}/upstream.${artifact}" "${TMP_DIR}/local.${artifact}" || true
    DRIFT_COUNT=$((DRIFT_COUNT + 1))
  fi
done

if [[ ${DRIFT_COUNT} -gt 0 ]]; then
  echo ""
  echo "Detected ${DRIFT_COUNT} drift(s). Reconcile by editing the Nix" >&2
  echo "skill file under ${SKILLS_DIR}/openspec-<artifact>.nix and recording" >&2
  echo "the divergence in openspec/schemas/rosh-spec-driven/CHANGES.md." >&2
  exit 1
fi

echo "OK: no drift in openspec-* skills"
