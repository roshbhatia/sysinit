{ scanLib, pkgs, ... }:
scanLib.mkScanCheck {
  name = "shell-scripts-shellcheck";
  root = ../.;
  unit = "shell scripts";
  tools = [ pkgs.shellcheck ];
  findArgs = "-type f ! -path '*/.git/*'";
  # Shebang as well as extension, and not `$`-anchored: `#!/usr/bin/env bash -e`
  # is exactly how a script escapes an anchored pattern. zsh belongs to the zsh
  # parse check.
  filter = ''
    case "$f" in
      *.sh) ;;
      *)
        shebang="$(head -n1 "$f" 2> /dev/null)"
        case "$shebang" in
          *zsh*) continue ;;
        esac
        printf '%s' "$shebang" \
          | grep -qE '^#!.*[/ ](ba)?sh([[:space:]]|$)' || continue
        ;;
    esac
  '';
  validate = "shellcheck -s bash \"$f\"";
  hint = "Fix the finding, or add a targeted 'shellcheck disable' with a reason.";
  requireNonEmpty =
    map
      (path: {
        inherit path;
        findArgs = "-type f \\( -name '*.sh' -o -name 'pre-commit' \\)";
      })
      [
        "modules/home/programs/llm/runtime"
        "modules/home/programs/llm/harnesses"
        "modules/home/programs/llm/skills"
        "hack"
        ".githooks"
      ];
}
