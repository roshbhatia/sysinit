{
  pkgs,
  ...
}:
# Structural gate for the Nix sources, complementing `nixfmt` (layout only) and
# the parse checks (syntax only). The rules live in `.ast-grep/rules/` and are
# described there; this check only runs them.
#
# `ast-grep scan` exits non-zero on an `error` rule and zero on a `warning` one,
# so a rule's severity is what decides whether it gates CI. That split is
# deliberate: `nix-overlay-test-skip` reports on overrides that are already in
# the tree on purpose, and must stay visible without failing the build.
#
# `-c` is load-bearing. ast-grep finds `sgconfig.yml` by walking up from the
# working directory, and the build runs in a sandbox whose cwd is a temporary
# directory outside the source, so discovery finds nothing.
pkgs.runCommand "ast-grep-nix-rules-check"
  {
    nativeBuildInputs = [ pkgs.ast-grep ];
  }
  ''
    src=${../.}

    # Per rule directory, for the reason the lua and zsh checks give: one
    # directory keeps the total above zero while the other silently drops out
    # of coverage after a move.
    rules=0
    for dir in .ast-grep/rules modules/home/programs/ast-grep/rules; do
      n=$(find "$src/$dir" -name '*.yml' | wc -l)
      if [ "$n" -eq 0 ]; then
        echo "FAIL: $dir contributed no rule files." >&2
        echo "It moved or was renamed, and this check stopped covering it." >&2
        exit 1
      fi
      rules=$((rules + n))
    done

    # Every rule declares `language: nix`, so a run that reads no .nix file at
    # all would pass while covering nothing.
    sources=$(find "$src" -name '*.nix' ! -path '*/.git/*' | wc -l)
    if [ "$sources" -eq 0 ]; then
      echo "FAIL: no .nix files found under the flake source." >&2
      exit 1
    fi

    if ! ast-grep scan -c "$src/sgconfig.yml" "$src"; then
      echo "" >&2
      echo "Fix the source, or change the rule. The rule files are under" >&2
      echo ".ast-grep/rules/ and modules/home/programs/ast-grep/rules/." >&2
      exit 1
    fi

    echo "OK: $rules ast-grep rules pass over $sources nix files" | tee "$out"
  ''
