{
  pkgs,
  ...
}:
# Behavioral guard for the machine-wide default (Lever 2). Assert a
# bare `openspec new change` writes `schema: spec-driven`. This
# catches a newly added or moved default-schema site that the
# overlay's `--replace-fail` patch is blind to. Hermetic: HOME and
pkgs.runCommand "openspec-default-schema-check"
  {
    nativeBuildInputs = [ pkgs.openspec ];
  }
  ''
    export HOME="$TMPDIR/home"
    export XDG_DATA_HOME="$TMPDIR/xdg"
    export OPENSPEC_TELEMETRY=0
    export CI=true
    mkdir -p "$TMPDIR/proj"
    # Guarded: an unguarded cd that fails leaves every assertion below running in
    # the wrong directory, where it can pass for the wrong reason.
    cd "$TMPDIR/proj" || exit 1
    schema_source="$(openspec schema which spec-driven 2>&1)"
    if ! grep -q "Source: package" <<< "$schema_source"; then
      echo "FAIL: spec-driven is not package-owned:" >&2
      echo "$schema_source" >&2
      exit 1
    fi
    openspec new change probe > /dev/null 2>&1 || true
    cfg="$(find . -name config.yaml -path '*openspec*' | head -n1)"
    if [ -z "$cfg" ]; then
      echo "FAIL: bare 'openspec new change' wrote no openspec config.yaml" >&2
      exit 1
    fi
    if grep -q "schema: spec-driven" "$cfg"; then
      echo "OK: bare 'openspec new change' defaults to spec-driven" | tee "$out"
    else
      echo "FAIL: default schema is not spec-driven. Wrote:" >&2
      cat "$cfg" >&2
      exit 1
    fi
  ''
