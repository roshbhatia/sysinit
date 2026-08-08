{
  pkgs,
  ...
}:
pkgs.runCommand "schema-templates-conform-check"
  {
    nativeBuildInputs = [
      pkgs.specutil
      pkgs.jq
    ];
  }
  ''
    tmpl=${../modules/home/programs/llm/openspec-schema}/templates
    root="$TMPDIR/proj"
    change="$root/openspec/changes/probe"
    mkdir -p "$change"
    echo "schema: spec-driven" > "$root/openspec/config.yaml"
    cp "$tmpl/proposal.md" "$change/proposal.md"
    cp "$tmpl/design.md"   "$change/design.md"
    cp "$tmpl/tasks.md"    "$change/tasks.md"

    exempt='["review-decision-current"]'

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
