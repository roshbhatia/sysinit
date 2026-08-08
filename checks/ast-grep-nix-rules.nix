{
  pkgs,
  ...
}:
pkgs.runCommand "ast-grep-nix-rules-check"
  {
    nativeBuildInputs = [ pkgs.ast-grep ];
  }
  ''
    src=${../.}

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

    sources=$(find "$src" -name '*.nix' ! -path '*/.git/*' | wc -l)
    if [ "$sources" -eq 0 ]; then
      echo "FAIL: no .nix files found under the flake source." >&2
      exit 1
    fi

    mkdir -p fixture
    cat > fixture/violation.nix <<'FIXTURE'
    { lib, pkgs, ... }:
    with lib;
    { path = pkgs.lib.makeBinPath [ ]; env = builtins.getEnv "HOME"; }
    FIXTURE
    if ast-grep scan -c "$src/sgconfig.yml" fixture > /dev/null 2>&1; then
      echo "FAIL: the known-bad fixture produced no error." >&2
      echo "ast-grep loaded no rules. Check ruleDirs in sgconfig.yml: a rule file" >&2
      echo "that is itself a symlink is skipped by the directory walk." >&2
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
