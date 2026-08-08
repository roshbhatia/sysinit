{
  pkgs,
  ...
}:
pkgs.runCommand "citelock-check"
  {
    nativeBuildInputs = [
      pkgs.bash
      pkgs.sysinit-agent
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
      if ! sysinit-agent citelock verify "$dir"; then
        fail=1
      fi
    done < <(find "$changes" -name citations.lock 2> /dev/null)
    if [ "$fail" -ne 0 ]; then
      echo "FAIL: citelock offline gate failed" >&2
      exit 1
    fi

    gate="sysinit-agent citelock"

    mkdir -p "$TMPDIR/nolock"
    if ! nolock_out="$($gate verify "$TMPDIR/nolock" 2>&1)"; then
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

    mkdir -p "$TMPDIR/badlock"
    echo '{"records":[{"id":"unanchored"}]}' > "$TMPDIR/badlock/citations.lock"
    if badlock_out="$($gate verify "$TMPDIR/badlock" 2>&1)"; then
      echo "FAIL: citelock verify accepted a record with no source, quote, snapshot, or sha256." >&2
      echo "The offline gate is the only thing standing between a hallucinated citation and a merge." >&2
      exit 1
    fi
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
