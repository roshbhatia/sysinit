#!/usr/bin/env bash
# Deterministic rubric-lint for a rosh-spec-driven openspec change. This is the
# reproducible half of adversarial review: it checks only facts the author
# STATES (declared markers), never facts it must infer from prose, so two runs
# always agree. The LLM refutation half (see the adversarial-review skill) is
# stabilized but NOT deterministic; this script does not attempt it.
#
# Checks over openspec/changes/<name>/:
#   - specs/**/*.md: every `### Requirement:` has at least one scenario whose
#     first bullet declares `- **POLARITY** negative` (negative-scenario rule,
#     read from the declared marker, not from failure words in prose).
#   - design.md: has `## Decisions`, `## Rollout & Gating`, `## Adversarial
#     Review`; every `- Decision:` bullet is followed by an
#     `- Alternative rejected:` line.
#   - tasks.md: every `## <n>.` slice has an adversarial-review checkbox line.
#   - proposal.md: a `### Non-goals` block is present.
#
# Usage: ./hack/specreview.sh <change-dir>
# Exit non-zero (with named violations) on any rubric failure.

set -euo pipefail

dir="${1:-.}"
[[ -d ${dir} ]] || {
  echo "specreview: not a directory: ${dir}" >&2
  exit 2
}

fail=0
violation() {
  echo "specreview: FAIL: $*" >&2
  fail=1
}

# --- specs: every requirement has a declared-negative scenario --------------
while IFS= read -r spec; do
  [[ -z ${spec} ]] && continue
  # Split the file into requirement blocks and check each for a negative marker.
  awk '
    /^### Requirement:/ {
      if (name != "" && neg == 0) print "NOFAIL:" name
      name = $0; sub(/^### Requirement:[ ]*/, "", name); neg = 0
    }
    /^-[ ]+\*\*POLARITY\*\*[ ]+negative/ { neg = 1 }
    END { if (name != "" && neg == 0) print "NOFAIL:" name }
  ' "$spec" | while IFS= read -r line; do
    echo "${spec}: ${line#NOFAIL:}"
  done > /tmp/.specreview_missing 2> /dev/null || true
  if [[ -s /tmp/.specreview_missing ]]; then
    while IFS= read -r m; do violation "requirement without a declared-negative scenario: ${m}"; done < /tmp/.specreview_missing
  fi
  rm -f /tmp/.specreview_missing
done < <(find "${dir}/specs" -name '*.md' 2> /dev/null)

# --- design.md sections + rejected-alternative markers ----------------------
design="${dir}/design.md"
if [[ -f ${design} ]]; then
  for section in "## Decisions" "## Rollout & Gating" "## Adversarial Review"; do
    grep -Fq -- "$section" "$design" || violation "design.md missing required section: ${section}"
  done
  # Per-block: every `- Decision:` needs at least one following
  # `- Alternative rejected:` before the next decision. Counting in aggregate is
  # wrong (two alternatives under one decision would cover a bare one elsewhere).
  if ! awk '
    /^- Decision:/ { if (d && !a) bad = 1; d = 1; a = 0; next }
    /^  - Alternative rejected:/ { if (d) a = 1 }
    END { if (d && !a) bad = 1; exit bad ? 1 : 0 }
  ' "$design"; then
    violation "design.md has a '- Decision:' with no following '- Alternative rejected:' marker"
  fi
fi

# --- tasks.md: each non-Rollout slice has an adversarial-review checkbox -----
tasks="${dir}/tasks.md"
if [[ -f ${tasks} ]]; then
  # Per-slice: the review step must be a checkbox line inside the slice, not a
  # heading (a slice titled "Adversarial review …" must not self-satisfy).
  if ! awk '
    /^## [0-9]+\./ {
      if (inslice && !isrollout && !hasreview) bad = 1
      inslice = 1; hasreview = 0; isrollout = ($0 ~ /[Rr]ollout/); next
    }
    /^- \[[ x]\].*[Aa]dversarial [Rr]eview/ { if (inslice) hasreview = 1 }
    END { if (inslice && !isrollout && !hasreview) bad = 1; exit bad ? 1 : 0 }
  ' "$tasks"; then
    violation "a non-Rollout tasks.md slice has no adversarial-review checkbox"
  fi
fi

# --- proposal.md: Non-goals present -----------------------------------------
proposal="${dir}/proposal.md"
if [[ -f ${proposal} ]]; then
  grep -Fq -- "### Non-goals" "$proposal" || violation "proposal.md missing a '### Non-goals' block"
fi

if [[ ${fail} -ne 0 ]]; then
  echo "specreview: rubric-lint failed for ${dir}" >&2
  exit 1
fi
echo "specreview: rubric-lint passed for ${dir}"
