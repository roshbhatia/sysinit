{
  pkgs,
  ...
}:
# The schema's templates must be a conforming starting point. A change
# scaffolded verbatim from them has to pass the schema's own rubric,
# otherwise an author who fills in the template still trips the gate
# and has to reverse-engineer the rule from a failure. This caught the
pkgs.runCommand "schema-templates-conform-check"
  {
    nativeBuildInputs = [
      pkgs.specutil
      pkgs.jq
    ];
  }
  ''
    tmpl=${pkgs.openspec}/lib/openspec/schemas/spec-driven/templates
    root="$TMPDIR/proj"
    change="$root/openspec/changes/probe"
    mkdir -p "$change"
    echo "schema: spec-driven" > "$root/openspec/config.yaml"
    cp "$tmpl/proposal.md" "$change/proposal.md"
    cp "$tmpl/design.md"   "$change/design.md"
    cp "$tmpl/tasks.md"    "$change/tasks.md"

    # review-decision-current: wants a recorded human verdict in
    # specutil.review.yaml. A fresh scaffold has no reviewer yet.
    exempt='["review-decision-current"]'

    # `specutil check` exits 1 on any error finding, so read the
    # findings rather than the exit code. A non-JSON body means the
    # tool itself broke, which must still fail loudly.
    specutil check "$change" --as json > "$TMPDIR/findings.json" || true
    if ! jq -e . "$TMPDIR/findings.json" > /dev/null 2>&1; then
      echo "FAIL: specutil check produced no parseable JSON:" >&2
      cat "$TMPDIR/findings.json" >&2
      exit 1
    fi

    blocking=$(jq --argjson exempt "$exempt" \
      '[.findings[] | select(.severity == "error") | select(.rule as $r | $exempt | index($r) | not)]' \
      "$TMPDIR/findings.json")

    if [ "$(jq 'length' <<< "$blocking")" -eq 0 ]; then
      echo "OK: a change scaffolded from the templates passes the rubric" | tee "$out"
    else
      echo "FAIL: the schema templates do not satisfy the schema's own rubric." >&2
      jq -r '.[] | "  \(.rule)  \(.file): \(.msg)"' <<< "$blocking" >&2
      echo "Fix the templates so a scaffolded change starts out conforming." >&2
      exit 1
    fi
  ''
