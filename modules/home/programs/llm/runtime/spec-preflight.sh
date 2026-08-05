# Deterministic half of the spec-driven authoring rules, as one command.
#
# The schema's artifact instructions used to restate what `specutil check` and
# `citelock` already enforce: no em-dash, no bolded bullet lead, every phase
# declares SHAPE, every external-factual claim is anchored. Prose that mirrors a
# gate has two failure modes and both happened here. It drifts from the gate, and
# it invites an author to satisfy the prose instead of running the gate.
#
# So the instructions now say "run this and fix what it reports", and this is the
# thing they run. It only reports; it never edits an artifact.
#
# Usage: spec-preflight <proposal|design|tasks|all> [change-name]

set -uo pipefail

stage="${1:-all}"
change="${2:-}"

fail=0
note() { printf '  %s\n' "$1"; }
section() { printf '\n%s\n' "$1"; }

root=$(git rev-parse --show-toplevel 2> /dev/null || pwd -P)
cd "$root" || exit 1

if [ -z "$change" ]; then
  # Most recently modified active change, which is the one being authored.
  change=$(find openspec/changes -mindepth 1 -maxdepth 1 -type d -not -name archive 2> /dev/null |
    while IFS= read -r d; do printf '%s %s\n' "$(stat -f %m "$d" 2> /dev/null || stat -c %Y "$d")" "$d"; done |
    sort -rn | head -1 | cut -d' ' -f2-)
  change=${change##*/}
fi

if [ -z "$change" ] || [ ! -d "openspec/changes/$change" ]; then
  echo "spec-preflight: no change to check (looked for openspec/changes/<name>)" >&2
  exit 2
fi

dir="openspec/changes/$change"
printf 'spec-preflight: %s (stage: %s)\n' "$change" "$stage"

# 1. The rubric. specutil owns em-dashes, bolded leads, phase markers, task ids,
# dependency cycles, and the review-decision freshness gate.
section "specutil check"
if out=$(specutil check --change "$change" 2>&1); then
  note "pass"
else
  printf '%s\n' "$out" | sed 's/^/  /'
  fail=1
fi

# 2. Citations. A change with no external-factual claim has no lock and that is
# correct, so an absent lock is silence, not a failure.
section "citations"
if [ -f "$dir/citations.lock" ]; then
  if out=$(citelock verify --change "$change" 2>&1) || out=$(citelock verify 2>&1); then
    note "lock verifies"
  else
    printf '%s\n' "$out" | sed 's/^/  /'
    fail=1
  fi
else
  note "no citations.lock; correct only if this change asserts no external fact"
  note "if it does: citelock capture, then re-run"
fi

# 3. Reuse survey. The rule says reference the closest existing implementation by
# path. A grep cannot judge closeness, so this lists candidates for the author to
# rule on rather than pretending to decide.
if [ "$stage" = "proposal" ] || [ "$stage" = "all" ]; then
  section "reuse candidates (rule 1: name what is reused vs introduced)"
  if [ -f "$dir/proposal.md" ]; then
    terms=$(grep -oE '\b[a-z][a-z0-9-]{4,}\b' "$dir/proposal.md" 2> /dev/null |
      sort | uniq -c | sort -rn | awk '$1 >= 3 {print $2}' | head -6)
    found=0
    for term in $terms; do
      hits=$(rg -l --glob '!openspec/**' --glob '!**/.git/**' -- "$term" . 2> /dev/null | head -3)
      if [ -n "$hits" ]; then
        note "$term:"
        printf '%s\n' "$hits" | sed 's/^/      /'
        found=1
      fi
    done
    [ "$found" -eq 1 ] || note "no existing module matched the proposal's own vocabulary"
  else
    note "no proposal.md yet"
  fi
fi

# 4. Behavior section. It is the rubric every later artifact is judged against,
# so its absence is a hard failure rather than a style note.
if [ "$stage" = "proposal" ] || [ "$stage" = "all" ]; then
  section "behavior section"
  if [ -f "$dir/proposal.md" ] && grep -q '^## Behavior' "$dir/proposal.md"; then
    n=$(sed -n '/^## Behavior/,/^## /p' "$dir/proposal.md" | grep -c '^- ')
    note "present, $n entries"
    [ "$n" -gt 0 ] || { note "a Behavior section with no entries is not acceptance criteria"; fail=1; }
  else
    note "MISSING. Acceptance criteria live here; nothing is promoted to openspec/specs/"
    fail=1
  fi
fi

section "result"
if [ "$fail" -eq 0 ]; then
  note "deterministic checks pass; the judgement-based rules remain yours"
  exit 0
fi
note "fix the above, then re-run"
exit 1
