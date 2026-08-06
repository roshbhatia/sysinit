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
# Usage: spec-preflight <citations|review|proposal|design|tasks|all> [change-name]

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

# 0. Schema drift. Three different things are called "openspec" and only one of
# them is what the CLI reads:
#
#   modules/home/programs/llm/openspec-schema/  the Nix SOURCE you edit
#   ~/.local/share/openspec/schemas/<name>/     the INSTALLED copy openspec reads
#   openspec/                                   THIS repo's planning dir
#
# Editing the source has no effect until `nh darwin switch` relinks the middle
# one, so an author can change a rule, re-run openspec, and be told the old rule.
# That failure is silent and costs a whole debugging detour, so name it up front.
# Only sysinit carries the source; everywhere else this stage is a no-op.
schema_src="modules/home/programs/llm/openspec-schema"
if [ -f "$schema_src/schema.yaml" ]; then
  section "schema drift (source vs installed)"
  schema_name=$(sed -n 's/^name:[[:space:]]*//p' "$schema_src/schema.yaml" | head -1)
  installed="${XDG_DATA_HOME:-$HOME/.local/share}/openspec/schemas/${schema_name:-spec-driven}"
  if [ ! -d "$installed" ]; then
    note "installed schema '$schema_name' not found at $installed"
  elif diff -qr "$schema_src" "$installed" > /dev/null 2>&1; then
    note "pass: source and installed agree"
  else
    note "DRIFT: openspec is reading the installed copy, not your edit"
    diff -qr "$schema_src" "$installed" 2> /dev/null | sed 's/^/    /' | head -6
    note "  run a switch to apply; until then openspec enforces the OLD schema"
    # Not a failure. Editing the schema and authoring a change in the same
    # session is normal, and blocking the second on the first would be wrong.
  fi
fi

# 1. The rubric. specutil owns em-dashes, bolded leads, phase markers, task ids,
# dependency cycles, and the review-decision freshness gate.
section "specutil check"
if out=$(specutil check --change "$change" 2>&1); then
  note "pass"
else
  printf '%s\n' "$out" | sed 's/^/  /'
  fail=1
fi

# 2. Citations, as ordered stages. Each answers one question a command can
# decide, and the order matters: a later stage is meaningless if an earlier one
# failed, so the first failure stops the rest rather than emitting noise about a
# file that does not parse.
#
# What is NOT here: "is every external-factual claim pinned". Deciding which
# sentence asserts an external fact is a judgement, and a script that pretended
# to make it would give false assurance. That one stays with the author and the
# review.
if [ "$stage" = "citations" ] || [ "$stage" = "proposal" ] || [ "$stage" = "all" ]; then
  section "citations"
  lock="$dir/citations.lock"

  # Stage 1: exists. An absent lock cannot distinguish "nothing to cite" from
  # "nobody looked", so the schema requires the file even when it is empty.
  if [ ! -f "$lock" ]; then
    note "FAIL exists: no citations.lock"
    note '  a change with no external-factual claim still needs one: {"records": []}'
    fail=1
  elif ! records=$(jq -e '.records' "$lock" 2> /dev/null); then
    # Stage 2: parses, with a records array.
    note "FAIL parses: citations.lock has no .records array"
    fail=1
  else
    count=$(printf '%s' "$records" | jq 'length')
    note "pass exists: $count record(s)"

    # Stage 3: valid. citelock owns snapshot sha256 and quote anchoring.
    if out=$(citelock verify "$dir" 2>&1); then
      note "pass valid: citelock verify"
    else
      printf '%s\n' "$out" | sed 's/^/    /'
      fail=1
    fi

    # Stage 4: snapshots present. verify covers this, but naming it separately
    # tells an author which of the two things to fix.
    missing=0
    while IFS= read -r snap; do
      [ -n "$snap" ] || continue
      [ -f "$dir/$snap" ] || {
        note "FAIL snapshot: missing $snap"
        missing=1
      }
    done <<< "$(printf '%s' "$records" | jq -r '.[].snapshot // empty')"
    [ "$missing" -eq 0 ] || fail=1

    # Stage 5 and 6: the prose link, both directions. A lock the prose never
    # points at makes a reader diff two files by hand; a reference naming no
    # record is a claim pretending to be pinned.
    prose=$(cat "$dir"/*.md 2> /dev/null || true)
    uncited=0
    while IFS= read -r id; do
      [ -n "$id" ] || continue
      case "$prose" in
        *"[cite: $id]"*) ;;
        *)
          note "FAIL uncited: record '$id' is never referenced as [cite: $id]"
          uncited=1
          ;;
      esac
    done <<< "$(printf '%s' "$records" | jq -r '.[].id // empty')"
    [ "$uncited" -eq 0 ] || fail=1

    dangling=0
    while IFS= read -r ref; do
      [ -n "$ref" ] || continue
      if ! printf '%s' "$records" | jq -e --arg id "$ref" 'any(.[]; .id == $id)' > /dev/null 2>&1; then
        note "FAIL dangling: [cite: $ref] names no record in citations.lock"
        dangling=1
      fi
    done <<< "$(printf '%s' "$prose" | grep -oE '\[cite: [^]]+\]' | sed 's/^\[cite: //; s/\]$//' | sort -u)"
    [ "$dangling" -eq 0 ] || fail=1

    [ "$uncited" -eq 1 ] || [ "$dangling" -eq 1 ] || note "pass linked: prose and lock agree"

    # Stage 7: freshness. A WARNING and never a failure, deliberately. A gate
    # that flips to red because the clock moved makes the build a function of
    # the date, so an untouched change would start failing on its own. Staleness
    # is a prompt to run `citelock recheck`, not a defect in the change.
    now=$(date +%s)
    stale=0
    while IFS= read -r line; do
      [ -n "$line" ] || continue
      id=${line%% *}
      when=${line##* }
      then_s=$(date -d "$when" +%s 2> /dev/null || date -j -f %Y-%m-%d "$when" +%s 2> /dev/null || echo "")
      [ -n "$then_s" ] || continue
      days=$(((now - then_s) / 86400))
      if [ "$days" -gt "${SPEC_PREFLIGHT_CITATION_MAX_AGE_DAYS:-90}" ]; then
        note "warn stale: '$id' captured $days days ago; citelock recheck"
        stale=1
      fi
    done <<< "$(printf '%s' "$records" | jq -r '.[] | "\(.id) \(.accessed)"')"
    [ "$stale" -eq 1 ] || note "pass fresh: no record past the age threshold"
  fi
fi

# 2b. Review decision. openspec decides an artifact is complete by file
# existence alone (`detectCompleted` in artifact-graph/state.js), so
# `apply.requires: [tasks, review]` unblocks apply the moment review.md exists,
# whatever it says. That makes the owner gate real: a review whose decision is
# still `pending` is not a completed review, and nothing in openspec can say so.
if [ "$stage" = "review" ] || [ "$stage" = "tasks" ] || [ "$stage" = "all" ]; then
  section "review decision"
  review="$dir/review.md"
  if [ ! -f "$review" ]; then
    note "FAIL exists: no review.md"
    note "  apply is gated on this artifact; generate it before implementing"
    fail=1
  else
    decision=$(sed -n 's/^Decision:[[:space:]]*//p' "$review" | head -1)
    case "$decision" in
      "run approved" | "not-run approved")
        note "pass decision: $decision"
        ;;
      "" | pending | "<pending"*)
        note "FAIL decision: still '${decision:-unset}'"
        note "  the owner records this, not the agent. Elicit it before applying."
        fail=1
        ;;
      *)
        note "FAIL decision: unrecognised value '$decision'"
        note "  expected: run approved | not-run approved"
        fail=1
        ;;
    esac
    # A terminal state that hands back open work must actually list it.
    state=$(sed -n 's/^State:[[:space:]]*//p' "$review" | head -1)
    case "$state" in
      CAPPED | STALLED | CHURNING)
        if sed -n '/^## Open objections/,$p' "$review" | grep -qE '^- \S'; then
          note "pass open-objections: $state lists them"
        else
          note "FAIL open-objections: $state with none listed is a contradiction"
          fail=1
        fi
        ;;
      CLEAN | NOT-RUN) note "pass terminal: $state" ;;
      # `pending` is the pre-run state: the artifact exists and the loop has not
      # started, which is exactly where a review sits while it waits on the
      # owner. Treating it as unrecognised made a correctly-authored review warn.
      pending) note "pass terminal: pending (loop not started)" ;;
      "") ;;
      *) note "warn terminal: unrecognised state '$state'" ;;
    esac
  fi
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
    [ "$n" -gt 0 ] || {
      note "a Behavior section with no entries is not acceptance criteria"
      fail=1
    }
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
