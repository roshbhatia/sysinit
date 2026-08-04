{
  pkgs,
  ...
}:
# Offline citation gate: run citelock's offline stages over every
# openspec change that ships a citations.lock. Pure function of the
# tree (no network, no MCP); the same gate the pre-commit hook runs.
# A change with no citations.lock is a no-op.
pkgs.runCommand "citelock-check"
  {
    nativeBuildInputs = [
      pkgs.jq
      pkgs.bash
    ];
  }
  ''
    changes=${../openspec/changes}
    found=0
    fail=0
    while IFS= read -r lock; do
      [ -z "$lock" ] && continue
      found=1
      dir="$(dirname "$lock")"
      if ! bash ${../modules/home/programs/llm/skills/citation-verification/citelock.sh} verify "$dir"; then
        fail=1
      fi
    done < <(find "$changes" -name citations.lock 2> /dev/null)
    if [ "$fail" -ne 0 ]; then
      echo "FAIL: citelock offline gate failed" >&2
      exit 1
    fi

    # No change currently ships a citations.lock, so the loop above
    # never executes the script and this check passed on a path
    # literal alone. Fixtures make it run: without them, breaking
    # citelock's lockless return or its format lint left every check
    # green until the first change to carry a lock.
    gate=${../modules/home/programs/llm/skills/citation-verification/citelock.sh}

    # Both fixtures assert the REASON, not just the exit code. An exit
    # code alone cannot tell the intended failure from an incidental
    # one: `require_tool jq` also dies with status 1, so dropping
    # pkgs.jq from nativeBuildInputs would leave an exit-code-only
    # assertion green while the format lint never ran.
    mkdir -p "$TMPDIR/nolock"
    if ! nolock_out="$(bash "$gate" verify "$TMPDIR/nolock" 2>&1)"; then
      echo "FAIL: citelock verify must be a no-op for a directory with no citations.lock." >&2
      echo "The pre-commit hook runs it over every change dir, so a non-zero here blocks every commit." >&2
      printf '%s\n' "$nolock_out" | sed 's/^/    /' >&2
      exit 1
    fi
    case "$nolock_out" in
      *"nothing to verify"*) ;;
      *)
        echo "FAIL: citelock verify exited 0 for a lockless directory without taking the no-op path." >&2
        printf '%s\n' "$nolock_out" | sed 's/^/    /' >&2
        exit 1
        ;;
    esac

    # A record missing its required fields must fail the format lint.
    # This is the cheapest input that reaches a real assertion: it needs
    # no snapshot and no network.
    mkdir -p "$TMPDIR/badlock"
    echo '{"records":[{"id":"unanchored"}]}' > "$TMPDIR/badlock/citations.lock"
    if badlock_out="$(bash "$gate" verify "$TMPDIR/badlock" 2>&1)"; then
      echo "FAIL: citelock verify accepted a record with no source, quote, snapshot, or sha256." >&2
      echo "The offline gate is the only thing standing between a hallucinated citation and a merge." >&2
      exit 1
    fi
    # Naming the record id proves the lint parsed the lock and reached
    # that record, which a bare non-zero exit does not.
    case "$badlock_out" in
      *"[unanchored] format:"*) ;;
      *)
        echo "FAIL: citelock verify rejected the bad lock for the wrong reason." >&2
        echo "Expected the format lint to name record 'unanchored'; it reported:" >&2
        printf '%s\n' "$badlock_out" | sed 's/^/    /' >&2
        exit 1
        ;;
    esac

    echo "OK: citelock offline gate ($([ "$found" -eq 1 ] && echo 'all locks pass' || echo 'no locks present'), fixtures pass)" | tee "$out"
  ''
