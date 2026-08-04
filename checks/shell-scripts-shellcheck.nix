{
  pkgs,
  ...
}:
# shellcheck gate for the authored shell scripts.
#
# `pkgs.writeShellApplication` already runs shellcheck on what it wraps,
# but that only covers a script someone remembered to wrap. `statusline.sh`
pkgs.runCommand "shell-scripts-shellcheck-check"
  {
    nativeBuildInputs = [ pkgs.shellcheck ];
  }
  ''
    src=${../.}
    found=0
    fail=0
    while IFS= read -r f; do
      [ -z "$f" ] && continue
      case "$f" in
        *.sh) ;;
        *)
          # Not `$`-anchored: `#!/usr/bin/env bash -e` and
          # `#!/bin/bash --posix` are exactly how a script escapes a
          # `$`-anchored pattern. zsh is excluded explicitly, since
          # those files belong to the zsh parse check.
          shebang="$(head -n1 "$f" 2> /dev/null)"
          case "$shebang" in
            *zsh*) continue ;;
          esac
          printf '%s' "$shebang" \
            | grep -qE '^#!.*[/ ](ba)?sh([[:space:]]|$)' || continue
          ;;
      esac
      found=$((found + 1))
      if ! shellcheck -s bash "$f"; then
        fail=1
      fi
    done < <(find "$src" -type f ! -path '*/.git/*' | sort)

    # Per-subtree, for the reason given in the zsh and lua checks: a
    # whole-source `found -eq 0` guard never fires. Verified: deleting
    # modules/ left 6 files and the check still passed.
    require_nonempty() {
      if [ "$(find "$1" -type f \( -name '*.sh' -o -name 'pre-commit' \) | wc -l)" -eq 0 ]; then
        echo "FAIL: $1 contributed no shell scripts." >&2
        echo "It moved or was renamed, and this check stopped covering it." >&2
        fail=1
      fi
    }
    require_nonempty "$src/modules/home/programs/llm/runtime"
    require_nonempty "$src/modules/home/programs/llm/harnesses"
    # Skill-owned CLI sources now live beside their skill, so this
    # subtree carries shell scripts that nothing else canaried.
    require_nonempty "$src/modules/home/programs/llm/skills"
    require_nonempty "$src/hack"
    require_nonempty "$src/.githooks"

    if [ "$found" -eq 0 ]; then
      echo "FAIL: no shell scripts found in the flake source." >&2
      exit 1
    fi
    if [ "$fail" -ne 0 ]; then
      echo "Fix the finding, or add a targeted 'shellcheck disable' with a reason." >&2
      exit 1
    fi
    echo "OK: $found shell scripts pass shellcheck" | tee "$out"
  ''
