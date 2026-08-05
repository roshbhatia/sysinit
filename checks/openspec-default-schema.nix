{
  pkgs,
  ...
}:
# Behavioral guard for how this configuration owns the `spec-driven` name.
#
# It no longer patches openspec. The schema is installed to the user schema
# directory, where openspec resolves it ahead of its own built-in of the same
# name. Two properties have to hold, and only the second is about us:
#
#   1. A bare `openspec new change` still writes `schema: spec-driven`. That is
#      upstream's default and `openspec/config.yaml` depends on it.
#   2. A schema at the user path SHADOWS the package's built-in of that name.
#      This is the entire mechanism by which our templates are the ones used, so
#      an upstream change to schema resolution has to fail here.
#
# The previous version of this check asserted `Source: package`, which described
# the retired overlay that copied the schema into the CLI derivation. Left alone
# it would still pass, because upstream ships a `spec-driven` of its own from the
# package — a check green for a reason that has nothing to do with this repo.
#
# Hermetic: HOME and XDG_DATA_HOME are redirected into $TMPDIR, so the check
# reads the schema copied in below and never the developer's installed one.
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
    # Guarded: an unguarded cd that fails leaves every assertion below running in
    # the wrong directory, where it can pass for the wrong reason.
    cd "$TMPDIR/proj" || exit 1

    # 1. Upstream's default is still the name config.yaml pins.
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

    # 2. Installed at the user path, our schema shadows the package's built-in.
    # Copied rather than symlinked: openspec's discovery skips a symlinked schema
    # directory, which is the same reason home-manager installs it file by file.
    # $XDG_DATA_HOME, not $HOME/.local/share: it is exported above, and openspec
    # documents it as taking precedence on every platform when explicitly set.
    # Writing to the default path while that variable points elsewhere is exactly
    # the mistake this check exists to catch.
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
