# Moved verbatim from flake.nix. The expression is unchanged: its derivation path
# is asserted equal to the pre-move baseline in
# openspec/changes/decompose-flake-checks/drv-baseline.json.
{
  pkgs,
  lib,
  inputs,
  system,
  notifyIcons,
  managedFile,
  ...
}:
# Behavioral guard for the machine-wide default (Lever 2). Assert a
# bare `openspec new change` writes `schema: rosh-spec-driven`. This
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
    mkdir -p "$XDG_DATA_HOME/openspec/schemas"
    cp -r ${../openspec/schemas/rosh-spec-driven} "$XDG_DATA_HOME/openspec/schemas/rosh-spec-driven"
    chmod -R u+w "$XDG_DATA_HOME/openspec/schemas/rosh-spec-driven"
    mkdir -p "$TMPDIR/proj"
    cd "$TMPDIR/proj"
    openspec new change probe > /dev/null 2>&1 || true
    cfg="$(find . -name config.yaml -path '*openspec*' | head -n1)"
    if [ -z "$cfg" ]; then
      echo "FAIL: bare 'openspec new change' wrote no openspec config.yaml" >&2
      exit 1
    fi
    if grep -q "schema: rosh-spec-driven" "$cfg"; then
      echo "OK: bare 'openspec new change' defaults to rosh-spec-driven" | tee "$out"
    else
      echo "FAIL: default schema is not rosh-spec-driven. Wrote:" >&2
      cat "$cfg" >&2
      exit 1
    fi
  ''
