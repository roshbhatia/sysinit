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
# devin and agy block by exit code, not by a JSON permissionDecision, so
# they wrap the shared guard. Both wrappers were dead: the body called the
# guard by the bare name `claude-bash-guard`, which no harness puts on
# PATH, so the lookup failed, the output was empty, and the wrapper exited
# 0 for every command. Nothing noticed, because a fail-open guard and a
# working one are indistinguishable until something destructive is run.
#
# Drives the assembled wrappers, like destructive-guard-fixtures does, and
# asserts both directions: a destructive command must block, and an
# ordinary one must pass. Without the second assertion a deny-all wrapper
# would look like a fix.
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

    # Each harness names its shell tool differently; the guard reads
    # tool_input.command either way.
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

    # Commands the deny table actually claims, from
    # lib/allowlist.nix's destructiveDenyRules. `rm -rf` is deliberately
    # NOT among them: the table is git-specific, and asserting a block
    # for a command the guard never claimed would test the fixture
    # rather than the guard.
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
