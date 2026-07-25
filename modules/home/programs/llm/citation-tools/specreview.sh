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
# Usage (installed on PATH via citation-tools): specreview <change-dir>
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

# The phase-shape and writing-standard rules are newer than some changes, so
# grandfather anything under changes/archive/ (never retroactively fail it).
is_archived=0
[[ ${dir} == *"/archive/"* ]] && is_archived=1

# --- tasks.md: phase shapes (non-Rollout slice declares a shape; loop has ----
# STOP + MAX-ITERS; graph deps ids resolve to a sibling subtask). -------------
if [[ -f ${tasks} && ${is_archived} -eq 0 ]]; then
  awk '
    function flush() {
      if (inslice && !isrollout) {
        if (shape == "") print "slice " snum " has no - **SHAPE** marker"
        else if (shape == "loop") {
          if (!hasstop) print "loop slice " snum " has no - **STOP** marker"
          if (!hasmax)  print "loop slice " snum " has no - **MAX-ITERS** marker"
        } else if (shape == "graph") {
          for (i = 1; i <= ndeps; i++)
            if (!(depref[i] in ids)) print "graph slice " snum " has a dangling dependency: " depref[i]
        }
      }
    }
    /^## [0-9]+\./ {
      flush()
      inslice = 1; snum = $2; isrollout = ($0 ~ /[Rr]ollout/)
      shape = ""; hasstop = 0; hasmax = 0; ndeps = 0; delete ids; next
    }
    /^- \*\*SHAPE\*\*[ ]+loop/  { shape = "loop" }
    /^- \*\*SHAPE\*\*[ ]+graph/ { shape = "graph" }
    /^- \*\*STOP\*\*/           { hasstop = 1 }
    /^- \*\*MAX-ITERS\*\*/      { hasmax = 1 }
    /^- \[[ x]\][ ]+[0-9]+\.[0-9]+/ {
      line = $0; sub(/^- \[[ x]\][ ]+/, "", line)
      split(line, a, /[ ]+/); ids[a[1]] = 1
      if (match(line, /deps:`?[ ]+/)) {
        rest = substr(line, RSTART + RLENGTH); split(rest, d, /[ ,`]+/)
        for (k in d) if (d[k] ~ /^[0-9]+\.[0-9]+$/) { ndeps++; depref[ndeps] = d[k] }
      }
    }
    END { flush() }
  ' "$tasks" > /tmp/.specreview_shape 2> /dev/null || true
  if [[ -s /tmp/.specreview_shape ]]; then
    while IFS= read -r m; do violation "$m"; done < /tmp/.specreview_shape
  fi
  rm -f /tmp/.specreview_shape
fi

# --- writing standard (STE): no em-dash; no disallowed bolded bullet lead ----
if [[ ${is_archived} -eq 0 ]]; then
  {
    printf '%s\n' "${dir}/proposal.md" "${dir}/design.md" "${dir}/tasks.md"
    find "${dir}/specs" -name '*.md' 2> /dev/null
  } | while IFS= read -r art; do
    [[ -f ${art} ]] || continue
    # Both violation kinds are printed to stdout here and reported via
    # violation() below, so the reason survives (an in-loop violation() call
    # would have its stderr swallowed by the redirect).
    if LC_ALL=C grep -q $'\xe2\x80\x94' "$art"; then
      echo "em-dash in ${art}"
    fi
    awk '
      /^[ ]*- \*\*[A-Za-z]/ {
        m = $0; sub(/^[ ]*- \*\*/, "", m); sub(/\*\*.*/, "", m)
        allowed = " WHEN THEN AND POLARITY SHAPE STOP MAX-ITERS BREAKING "
        if (index(allowed, " " m " ") == 0) print "bolded bullet lead " FILENAME ": **" m "**"
      }
    ' "$art"
  done > /tmp/.specreview_ste 2> /dev/null || true
  if [[ -s /tmp/.specreview_ste ]]; then
    while IFS= read -r m; do violation "${m}"; done < /tmp/.specreview_ste
  fi
  rm -f /tmp/.specreview_ste
fi

if [[ ${fail} -ne 0 ]]; then
  echo "specreview: rubric-lint failed for ${dir}" >&2
  exit 1
fi
echo "specreview: rubric-lint passed for ${dir}"
