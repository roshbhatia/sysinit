{
  pkgs,
  managedFile,
  ...
}:
pkgs.runCommand "managed-file-merge3-check" { nativeBuildInputs = [ pkgs.jq ]; } ''
  prog=${pkgs.writeText "merge3.jq" managedFile.mergeProgram}
  fail=0

  ok() { # name base disk new expected
    got="$(jq -cs -f "$prog" <(echo "$2") <(echo "$3") <(echo "$4") 2>&1)"
    if [ "$got" = "$5" ]; then
      echo "ok   $1"
    else
      echo "FAIL $1: expected $5, got $got" >&2
      fail=1
    fi
  }

  refuses() { # name base disk new expected-substring
    if got="$(jq -cs -f "$prog" <(echo "$2") <(echo "$3") <(echo "$4") 2>&1)"; then
      echo "FAIL $1: expected a refusal, got $got" >&2
      fail=1
    elif ! printf '%s' "$got" | grep -q "$5"; then
      echo "FAIL $1: refusal did not mention '$5': $got" >&2
      fail=1
    else
      echo "ok   $1"
    fi
  }

  ok "undeclared key is deleted" \
    '{"a":1,"b":2}' '{"a":1,"b":2}' '{"a":1}' '{"a":1}'
  ok "undeclared key the owner edited is kept" \
    '{"a":1,"b":2}' '{"a":1,"b":9}' '{"a":1}' '{"a":1,"b":9}'
  ok "key the harness added is kept" \
    '{"a":1}' '{"a":1,"z":9}' '{"a":1}' '{"a":1,"z":9}'
  ok "nix-only change wins" \
    '{"a":1}' '{"a":1}' '{"a":2}' '{"a":2}'
  ok "owner-only change wins" \
    '{"a":1}' '{"a":5}' '{"a":1}' '{"a":5}'
  ok "both sides converged on one value" \
    '{"a":1}' '{"a":7}' '{"a":7}' '{"a":7}'
  ok "owner deletion sticks when nix is unchanged" \
    '{"a":1,"b":2}' '{"a":1}' '{"a":1,"b":2}' '{"a":1}'
  ok "nested: inner undeclare deletes, sibling add survives" \
    '{"s":{"a":1,"b":2}}' '{"s":{"a":1,"b":2,"z":9}}' '{"s":{"a":1}}' '{"s":{"a":1,"z":9}}'

  ok "nested 2 deep: undeclared subtree is deleted" \
    '{"p":{"o":{"k":1},"x":1}}' '{"p":{"o":{"k":1},"x":1}}' '{"p":{"x":1}}' '{"p":{"x":1}}'
  ok "nested 3 deep: undeclared leaf is deleted" \
    '{"p":{"o":{"k":1,"j":2}}}' '{"p":{"o":{"k":1,"j":2}}}' '{"p":{"o":{"k":1}}}' '{"p":{"o":{"k":1}}}'
  ok "nested 3 deep: harness addition beside it survives" \
    '{"p":{"o":{"k":1,"j":2}}}' '{"p":{"o":{"k":1,"j":2,"z":9}}}' '{"p":{"o":{"k":1}}}' '{"p":{"o":{"k":1,"z":9}}}'
  ok "nested: owner edit to an undeclared leaf is kept" \
    '{"p":{"o":{"k":1,"j":2}}}' '{"p":{"o":{"k":1,"j":99}}}' '{"p":{"o":{"k":1}}}' '{"p":{"o":{"j":99,"k":1}}}'

  refuses "three-way divergence on a scalar" \
    '{"a":1}' '{"a":5}' '{"a":9}' "conflict at .a"
  refuses "owner deleted a key nix then changed" \
    '{"a":1,"b":2}' '{"a":1}' '{"a":1,"b":3}' "conflict at .b"
  refuses "both sides added the same key differently" \
    '{"a":1}' '{"a":1,"z":1}' '{"a":1,"z":2}' "conflict at .z"

  if [ "$fail" -ne 0 ]; then
    echo "managed-file merge semantics regressed" >&2
    exit 1
  fi
  echo "OK: three-way merge semantics hold" > "$out"
''
