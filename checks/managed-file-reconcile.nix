{
  pkgs,
  lib,
  managedFile,
  ...
}:
# End-to-end coverage of the reconcile() shell function, not just the
# jq program. Five adversarial review rounds each found a defect in
# this region and four of them regressed the previous round's fix,
# because nothing exercised it. Every scenario below is a defect that
# actually shipped and was caught by hand.
let
  mf = managedFile;
  recFor =
    files:
    mf.mkReconciler {
      inherit pkgs;
      files = lib.mapAttrs (_: mf.mkTestFile) files;
    };
  schemaStrict = pkgs.writeText "strict.json" (
    builtins.toJSON {
      type = "object";
      additionalProperties = false;
      properties.ok = { };
    }
  );
  main = recFor {
    j = {
      path = "d/j.json";
      format = "json";
      content = {
        a = 1;
        keep.deep = true;
      };
    };
    y = {
      path = "d/y.yaml";
      format = "yaml";
      content = {
        mode = "smart";
        n = 0.2;
        # `ext` models the goose `extensions` block: one entry this repository
        # owns outright, one the harness is free to rewrite. Enforcing the
        # parent would flatten both, which is the outcome a path exists to avoid.
        ext = {
          owned.cmd = "/nix/store/owned";
          free.cmd = "/nix/store/free";
        };
        "dotted.key" = "nix";
      };
      enforce = [
        "mode"
        [
          "ext"
          "owned"
        ]
        # A literal top-level key whose NAME contains dots, as amp's VS Code-style
        # settings use. A string entry must never be split, or this would enforce
        # a nested path that does not exist and the real key would fall back to
        # merging with nothing reporting it.
        "dotted.key"
      ];
    };
    t = {
      path = "d/t.toml";
      format = "toml";
      content = {
        policy = "never";
        p.spec.effort = "high";
      };
    };
    skip = {
      path = "d/skip.json";
      createIfMissing = false;
      content.x = 1;
    };
    strict = {
      path = "d/strict.json";
      content.ok = 1;
      schema = "${schemaStrict}";
    };
  };
  # Same paths, one key undeclared and one changed, to drive
  # deletion-via-base and the conflict path.
  # The adopt path has no base, so the three-way merge has nothing to
  # compare against and cannot remove an undeclared key. `retire` is the
  # only thing that does, and it now applies on EVERY activation, not
  # only on adoption: a key that was never declared is absent from the
  # base too, and the merge preserves base-absent by design. Two
  # reconcilers, identical but for that list.
  adoptWith = recFor {
    a = {
      path = "d/adopt.json";
      format = "json";
      content.ok = 1;
      retire = [ "stale" ];
    };
  };
  adoptWithout = recFor {
    a = {
      path = "d/adopt.json";
      format = "json";
      content.ok = 1;
    };
  };

  # Same y target with the enforced path changed. Reproduces the goose defect:
  # the harness deletes a key the next Nix content also changes, which the merge
  # reports as an unresolvable conflict and which aborts the whole file.
  yV2 = recFor {
    y = {
      path = "d/y.yaml";
      format = "yaml";
      content = {
        mode = "smart";
        n = 0.2;
        ext = {
          owned.cmd = "/nix/store/owned2";
          free.cmd = "/nix/store/free";
        };
        "dotted.key" = "nix";
      };
      enforce = [
        "mode"
        [
          "ext"
          "owned"
        ]
        # A literal top-level key whose NAME contains dots, as amp's VS Code-style
        # settings use. A string entry must never be split, or this would enforce
        # a nested path that does not exist and the real key would fall back to
        # merging with nothing reporting it.
        "dotted.key"
      ];
    };
  };

  drop = recFor {
    j = {
      path = "d/j.json";
      format = "json";
      content.a = 1;
    };
  };
  allOff = recFor {
    j = {
      path = "d/j.json";
      enable = false;
    };
  };
in
pkgs.runCommand "managed-file-reconcile-check"
  {
    nativeBuildInputs = [
      pkgs.jq
      pkgs.yq-go
    ];
  }
  ''
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME/d"
    fail=0
    say() { echo "  $1"; }
    want() { # label actual expected
      if [ "$2" = "$3" ]; then say "ok   $1"; else echo "FAIL $1: got [$2] want [$3]" >&2; fail=1; fi
    }

    # The all-disabled kill switch must build. It is what you reach
    # for when the first switch misbehaves, and shellcheck fails the
    # derivation on unreachable helpers unless they are suppressed.
    want "all-disabled kill switch builds" "$([ -x ${allOff}/bin/sysinit-llm-reconcile ] && echo y)" "y"

    # forget_base is the only code a disabled file runs, and it is
    # the live path today: claude-json is disabled whenever
    # disabledBuiltinServers is empty. It derives the sidecar name a
    # second time, so a drift from reconcile() would be silent.
    mkdir -p "$HOME/d"; echo '{"a":1}' > "$HOME/d/j.json"; echo '{"a":1}' > "$HOME/d/.j.json.nix-base"
    ${allOff}/bin/sysinit-llm-reconcile > /dev/null
    want "disabled file drops its base" "$([ -e "$HOME/d/.j.json.nix-base" ] && echo kept || echo dropped)" "dropped"

    # --- `retire` removes a key the merge would otherwise keep --------
    # Two paths, both covered. On adoption there is no base to compare
    # against. On every later activation the key is base-ABSENT, which the
    # merge preserves on purpose, so a harness rewrite would make it
    # immortal. Dropping this list from a harness config is a silent
    # regression, and that regression was made and reverted once.
    mkdir -p "$HOME/d"
    echo '{"ok":1,"stale":true}' > "$HOME/d/adopt.json"
    ${adoptWithout}/bin/sysinit-llm-reconcile > /dev/null
    want "adopt without retire keeps the undeclared key" \
      "$(jq -r 'has("stale")' "$HOME/d/adopt.json")" "true"

    rm -f "$HOME/d/adopt.json" "$HOME/d/.adopt.json.nix-base"
    echo '{"ok":1,"stale":true}' > "$HOME/d/adopt.json"
    ${adoptWith}/bin/sysinit-llm-reconcile > /dev/null
    want "adopt with retire removes it" \
      "$(jq -r 'has("stale")' "$HOME/d/adopt.json")" "false"
    want "adopt with retire keeps the declared key" \
      "$(jq -r '.ok' "$HOME/d/adopt.json")" "1"
    # And the immortal case: the host has adopted, so a base exists, and
    # the harness writes the key again. It is base-absent, so the merge
    # keeps it; only `retire` removes it. This is the `powerline` defect.
    echo '{"ok":1}' > "$HOME/d/adopt.json"
    ${adoptWith}/bin/sysinit-llm-reconcile > /dev/null
    echo '{"ok":1,"stale":"compact"}' > "$HOME/d/adopt.json"
    ${adoptWith}/bin/sysinit-llm-reconcile > /dev/null
    want "retire removes a base-absent key the harness rewrote" \
      "$(jq -r 'has("stale")' "$HOME/d/adopt.json")" "false"
    rm -f "$HOME/d/adopt.json" "$HOME/d/.adopt.json.nix-base"
    want "disabled file itself untouched" "$(jq -r .a "$HOME/d/j.json")" "1"
    rm -f "$HOME/d/j.json"

    R=${main}/bin/sysinit-llm-reconcile

    # 1. seed, all three formats
    "$R" > /dev/null
    want "json seeded"  "$(jq -r .a "$HOME/d/j.json")" "1"
    want "yaml seeded"  "$(yq -r .mode "$HOME/d/y.yaml")" "smart"
    want "toml block style" "$(yq -p toml -r '.p.spec.effort' "$HOME/d/t.toml")" "high"
    want "yaml float kept" "$(yq -r .n "$HOME/d/y.yaml")" "0.2"
    # Block style, not a single-line flow blob. This asserts a property
    # of the OUTPUT, and is deliberately not mutation-sensitive to the
    # `... style=""` guard in managed-file.nix: verified with yq v4.53.3
    # that the guard only changes a YAML-to-YAML transform, where yq
    # preserves the source node style. The write path reads JSON, which
    # carries no style, so the guard is a no-op there. The assertion still
    # earns its place: it fails if the write path ever takes YAML input.
    #
    # Asserted as the absence of a flow mapping rather than as a line count. A
    # count re-pins on every fixture edit, and re-pinning a magic number is how
    # an assertion quietly stops testing what it names.
    want "yaml is block style" "$(grep -c '[{]' "$HOME/d/y.yaml" || true)" "0"
    want "yaml nests as a block" "$(yq -r '.ext.owned.cmd' "$HOME/d/y.yaml")" "/nix/store/owned"
    want "createIfMissing=false skipped" "$([ -e "$HOME/d/skip.json" ] && echo present || echo absent)" "absent"

    # createIfMissing=false must also refuse to seed over a leftover
    # store symlink. Seeding writes Nix-only content, which is what
    # the flag refuses; an earlier revision printed "leaves it alone"
    # and then seeded anyway.
    # A RESOLVING store path, not a dangling one: a dangling link
    # fails the `-e` test and would return for the wrong reason,
    # which is how an earlier version of this check passed against
    # the defect it was written to catch.
    ln -s ${schemaStrict} "$HOME/d/skip.json"
    "$R" > /dev/null 2>&1 || true
    want "skip target not seeded over a store link" "$([ -L "$HOME/d/skip.json" ] && echo link || echo seeded)" "link"

    # ...nor delete a zero-byte target it has just refused to create.
    # A crashed harness is exactly what produces one.
    rm -f "$HOME/d/skip.json"; : > "$HOME/d/skip.json"
    "$R" > /dev/null 2>&1 || true
    want "skip target zero-byte not deleted" "$([ -e "$HOME/d/skip.json" ] && echo present || echo gone)" "present"
    rm -f "$HOME/d/skip.json"

    # 2. idempotence
    cp "$HOME/d/j.json" "$TMPDIR/j1"; "$R" > /dev/null; "$R" > /dev/null
    want "idempotent over 3 runs" "$(cmp -s "$TMPDIR/j1" "$HOME/d/j.json" && echo same)" "same"

    # 3. a key the harness adds survives
    jq '.harnessAdded = "keep"' "$HOME/d/j.json" > "$TMPDIR/x" && mv "$TMPDIR/x" "$HOME/d/j.json"
    "$R" > /dev/null
    want "harness-added key kept" "$(jq -r .harnessAdded "$HOME/d/j.json")" "keep"

    # 4. a value the owner changes survives, unless enforced
    yq -i '.mode = "owner"' "$HOME/d/y.yaml"
    "$R" > /dev/null
    want "enforced key reasserted" "$(yq -r .mode "$HOME/d/y.yaml")" "smart"

    # --- an enforced PATH reaches one entry and leaves its siblings alone ----
    # Enforcing `ext` would win the same argument by flattening the block, and
    # the harness would write its runtime fields back on the next run. These
    # three assertions are what separate a path from that.
    yq -i '.ext.owned.cmd = "harness"' "$HOME/d/y.yaml"
    yq -i '.ext.owned.runtimeField = "written-by-harness"' "$HOME/d/y.yaml"
    yq -i '.ext.free.runtimeField = "written-by-harness"' "$HOME/d/y.yaml"
    "$R" > /dev/null
    want "enforced path reasserted" \
      "$(yq -r .ext.owned.cmd "$HOME/d/y.yaml")" "/nix/store/owned"
    want "enforced path drops harness fields under it" \
      "$(yq -r '.ext.owned | has("runtimeField")' "$HOME/d/y.yaml")" "false"
    want "sibling of an enforced path keeps its harness fields" \
      "$(yq -r .ext.free.runtimeField "$HOME/d/y.yaml")" "written-by-harness"

    # A string entry is one literal key, dots and all. amp really does enforce
    # "amp.permissions", so splitting a string would have addressed a nested path
    # that does not exist and dropped that enforcement without a word.
    yq -i '.["dotted.key"] = "harness"' "$HOME/d/y.yaml"
    "$R" > /dev/null
    want "literal dotted key reasserted" \
      "$(yq -r '.["dotted.key"]' "$HOME/d/y.yaml")" "nix"
    want "literal dotted key was not split into a path" \
      "$(yq -r 'has("dotted")' "$HOME/d/y.yaml")" "false"

    # The defect this path exists for: the harness DELETES a key that the next
    # Nix content also changes. Unenforced that is "live deleted it, nix changed
    # it", which the merge refuses, and refusing one key aborts the whole file.
    yq -i 'del(.ext.owned.cmd)' "$HOME/d/y.yaml"
    yq -i '.ext.owned.type = "builtin"' "$HOME/d/y.yaml"
    msg="$(${yV2}/bin/sysinit-llm-reconcile 2>&1 || true)"
    want "live-deleted key under an enforced path does not conflict" \
      "$(echo "$msg" | grep -c 'conflict at' || true)" "0"
    want "live-deleted key under an enforced path is restored to Nix" \
      "$(yq -r .ext.owned.cmd "$HOME/d/y.yaml")" "/nix/store/owned2"
    want "the rest of the file still updated" \
      "$(yq -r .ext.free.runtimeField "$HOME/d/y.yaml")" "written-by-harness"

    # 5. deletion via the base, with no tombstone list
    ${drop}/bin/sysinit-llm-reconcile > /dev/null
    want "undeclared key deleted" "$(jq -r 'has("keep")' "$HOME/d/j.json")" "false"
    want "harness key still kept" "$(jq -r .harnessAdded "$HOME/d/j.json")" "keep"

    # --- a declared key must win on EVERY activation -------------------
    # The three-way merge returns the DISK value whenever the Nix value
    # has not changed since the base, so a mergeable key wins exactly
    # once and never again. Measured before this assertion existed: base
    # stylix, disk dark, new stylix merged to dark, which is the
    # "generated theme is never selected" defect reappearing on the first
    # harness-side write. `enforce` is the only mechanism that fixes it.
    jq '.a = 999' "$HOME/d/j.json" > "$HOME/d/j.tmp" && mv "$HOME/d/j.tmp" "$HOME/d/j.json"
    ${main}/bin/sysinit-llm-reconcile > /dev/null
    want "a mergeable key loses to the harness on a later switch" \
      "$(jq -r .a "$HOME/d/j.json")" "999"
    jq '.a = 1' "$HOME/d/j.json" > "$HOME/d/j.tmp" && mv "$HOME/d/j.tmp" "$HOME/d/j.json"


    # 6. conflict refuses and leaves the target byte-identical
    jq '.a = 99' "$HOME/d/j.json" > "$TMPDIR/x" && mv "$TMPDIR/x" "$HOME/d/j.json"
    jq '.a = 55' "$HOME/d/.j.json.nix-base" > "$TMPDIR/x" && mv "$TMPDIR/x" "$HOME/d/.j.json.nix-base"
    cp "$HOME/d/j.json" "$TMPDIR/pre"
    msg="$("$R" 2>&1 || true)"
    want "conflict leaves target untouched" "$(cmp -s "$TMPDIR/pre" "$HOME/d/j.json" && echo same)" "same"
    want "conflict names the key" "$(echo "$msg" | grep -c 'conflict at .a')" "1"
    want "conflict shows three values" "$(echo "$msg" | grep -cE '^  (base|live|nix)')" "3"

    # 7. an unreadable base refuses rather than guessing
    rm -rf "$HOME/d2"; mkdir -p "$HOME/d2"
    echo 'not json {{{' > "$HOME/d/.j.json.nix-base"
    echo '{"a":1,"mine":true}' > "$HOME/d/j.json"
    msg="$("$R" 2>&1 || true)"
    want "unreadable base reported" "$(echo "$msg" | grep -c 'unreadable base')" "1"
    want "unreadable base leaves file" "$(jq -r .mine "$HOME/d/j.json")" "true"

    # 8. a schema failure leaves the target untouched
    rm -f "$HOME/d/.strict.json.nix-base"
    echo '{"ok":1,"bogus":2}' > "$HOME/d/strict.json"
    msg="$("$R" 2>&1 || true)"
    want "schema failure reported" "$(echo "$msg" | grep -c 'failed schema validation')" "1"
    want "schema failure keeps file" "$(jq -r .bogus "$HOME/d/strict.json")" "2"
    want "schema failure writes no base" "$([ -e "$HOME/d/.strict.json.nix-base" ] && echo wrote || echo none)" "none"

    # 9. a symlink the module does not own is refused, not replaced
    rm -rf "$HOME/d3"; mkdir -p "$HOME/d3"
    echo '{"precious":true}' > "$HOME/d3/real.json"
    rm -f "$HOME/d/j.json"; ln -s "$HOME/d3/real.json" "$HOME/d/j.json"
    msg="$("$R" 2>&1 || true)"
    want "user symlink refused" "$(echo "$msg" | grep -c 'does not own')" "1"
    want "user symlink intact" "$([ -L "$HOME/d/j.json" ] && echo y)" "y"
    want "pointed-at file intact" "$(jq -r .precious "$HOME/d3/real.json")" "true"

    # 10. a leftover store symlink IS replaced
    rm -f "$HOME/d/j.json" "$HOME/d/.j.json.nix-base"
    # Resolving, for the reason given on the skip fixture above: a
    # dangling link passes this assertion even with store-link
    # detection entirely disabled.
    ln -s ${schemaStrict} "$HOME/d/j.json"
    "$R" > /dev/null 2>&1 || true
    want "store symlink replaced" "$([ -f "$HOME/d/j.json" ] && [ ! -L "$HOME/d/j.json" ] && echo y)" "y"

    if [ "$fail" -ne 0 ]; then echo "reconcile() regressed" >&2; exit 1; fi
    echo "OK: reconcile() behaviour holds" > "$out"
  ''
