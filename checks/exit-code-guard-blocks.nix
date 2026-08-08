{
  pkgs,
  lib,
  ...
}:
let
  guards = import ../modules/home/programs/llm/lib/guards.nix { inherit lib; };
  wrapperFor =
    name:
    lib.getExe (
      guards.mkExitCodeGuard {
        inherit pkgs name;
      }
    );
in
pkgs.runCommand "exit-code-guard-blocks-check"
  {
    nativeBuildInputs = [
      pkgs.jq
      pkgs.bash
    ];
  }
  ''
    fail=0

    payload() {
      jq -cn --arg c "$1" '{tool_name:"exec",tool_input:{command:$c}}'
    }

    drive() {
      local wrapper="$1" label="$2" cmd="$3" want="$4" rc
      set +e
      payload "$cmd" | "$wrapper" > /dev/null 2>&1
      rc=$?
      set -e
      if [ "$want" = block ] && [ "$rc" -eq 0 ]; then
        echo "FAIL: $label exited 0 for '$cmd'; it must block by a non-zero exit." >&2
        echo "This is the fail-open shape: the wrapper could not reach the guard." >&2
        fail=1
      fi
      if [ "$want" = pass ] && [ "$rc" -ne 0 ]; then
        echo "FAIL: $label exited $rc for '$cmd'; an allowed command must pass." >&2
        echo "A guard that blocks everything is not a fix." >&2
        fail=1
      fi
    }

    for w in ${wrapperFor "devin-guard"} ${wrapperFor "gemini-exit-code-guard"}; do
      label="$(basename "$w")"
      drive "$w" "$label" 'git reset --hard HEAD~3' block
      drive "$w" "$label" 'git push --force origin main' block
      drive "$w" "$label" 'git commit --no-verify -m x' block
      drive "$w" "$label" 'ls -la' pass
      drive "$w" "$label" 'git status' pass
    done

    [ "$fail" -eq 0 ] || exit 1
    echo "OK: both exit-code guard wrappers block destructive commands and pass allowed ones" | tee "$out"
  ''
