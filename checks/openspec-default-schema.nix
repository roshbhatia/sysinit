{
  pkgs,
  ...
}:
pkgs.runCommand "openspec-default-schema-check"
  {
    nativeBuildInputs = [ pkgs.openspec ];
    schemaSrc = ../modules/home/programs/llm/openspec-schema;
  }
  ''
    export HOME="$TMPDIR/home"
    export XDG_DATA_HOME="$TMPDIR/xdg"
    export OPENSPEC_TELEMETRY=0
    export CI=true
    mkdir -p "$TMPDIR/proj"
    cd "$TMPDIR/proj" || exit 1

    openspec new change probe > /dev/null 2>&1 || true
    cfg="$(find . -name config.yaml -path '*openspec*' | head -n1)"
    if [ -z "$cfg" ]; then
      echo "FAIL: bare 'openspec new change' wrote no openspec config.yaml" >&2
      exit 1
    fi
    if ! grep -q "schema: spec-driven" "$cfg"; then
      echo "FAIL: default schema is not spec-driven. Wrote:" >&2
      cat "$cfg" >&2
      exit 1
    fi

    dest="$XDG_DATA_HOME/openspec/schemas/spec-driven"
    mkdir -p "$dest"
    cp -rL "$schemaSrc"/* "$dest"/
    chmod -R u+w "$dest"

    which_out="$(openspec schema which spec-driven 2>&1)"
    if ! grep -q "Source: user" <<< "$which_out"; then
      echo "FAIL: user-level spec-driven did not win resolution:" >&2
      echo "$which_out" >&2
      exit 1
    fi
    if ! grep -q "Shadows:" <<< "$which_out"; then
      echo "FAIL: openspec no longer reports shadowing the package built-in:" >&2
      echo "$which_out" >&2
      exit 1
    fi

    echo "OK: spec-driven defaults from upstream and resolves from the user path" | tee "$out"
  ''
