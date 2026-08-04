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
pkgs.runCommand "zsh-fragments-parse-check"
  {
    nativeBuildInputs = [ pkgs.zsh ];
  }
  ''
    src=${../modules}
    found=0
    fail=0
    while IFS= read -r f; do
      [ -z "$f" ] && continue
      found=$((found + 1))
      if ! zsh -n "$f"; then
        echo "FAIL: $f does not parse" >&2
        fail=1
      fi
    done < <(find "$src" -name '*.zsh' | sort)

    # A single aggregate guard is vacuous once the scan root holds
    # more than the subtree you care about: deleting the whole zsh
    # module still leaves other files and the check passes. Assert
    # each subtree contributes, so a move fails loudly.
    require_nonempty() {
      if [ "$(find "$1" -name "$2" | wc -l)" -eq 0 ]; then
        echo "FAIL: $1 contributed no $2 files." >&2
        echo "It moved or was renamed, and this check stopped covering it." >&2
        fail=1
      fi
    }
    require_nonempty "$src/home/programs/zsh" '*.zsh'

    if [ "$found" -eq 0 ]; then
      echo "FAIL: no .zsh fragments found under modules/." >&2
      exit 1
    fi
    if [ "$fail" -ne 0 ]; then
      echo "Fix the fragment; it is interpolated into every interactive shell." >&2
      exit 1
    fi
    echo "OK: $found zsh fragments parse" | tee "$out"
  ''
