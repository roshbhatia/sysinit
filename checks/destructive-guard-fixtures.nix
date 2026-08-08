{
  pkgs,
  lib,
  ...
}:
pkgs.runCommand "destructive-guard-fixtures-check"
  {
    nativeBuildInputs = [
      pkgs.jq
      pkgs.bash
    ];
  }
  ''
    guard=${
      lib.getExe (
        (import ../modules/home/programs/llm/lib/guards.nix { inherit lib; }).mkBashGuard {
          inherit pkgs;
          name = "bash-guard-under-test";
        }
      )
    }

    decision() {
      local out
      out="$(
        jq -cn --arg c "$1" '{tool_name:"Bash",tool_input:{command:$c}}' \
          | "$guard" \
          | jq -r '.hookSpecificOutput.permissionDecision // empty' 2> /dev/null
      )"
      [ -n "$out" ] || out=none
      printf '%s' "$out"
    }

    denied=(
      "git push --force"
      "git push --force-with-lease origin main"
      "git push -f"
      "git push origin main -f"
      "git commit --no-verify -m wip"
      "git commit --no-gpg-sign -m wip"
      "git reset --hard HEAD~1"
      "git clean -fd"
      "git branch -D feature"
      "git branch --delete --force feature"
    )

    allowed=(
      "git push"
      "git push origin main"
      "git push origin feature-f"
      "git status"
      "git reset HEAD~1"
      "git clean -n"
      "git branch -d feature"
      "nix flake check"
      "git push && rm -f /tmp/x"
      "git push origin main; rm -rf /tmp/x"
      "git reset HEAD~1 && printf -- --hard"
      "git branch -d old && grep -D pattern file"
    )

    denied+=(
      "git push -f && echo done"
      "git reset --hard HEAD~1; echo done"
    )

    fail=0
    for cmd in "''${denied[@]}"; do
      got="$(decision "$cmd")"
      if [ "$got" != "deny" ]; then
        echo "FAIL: expected deny, got '$got' for: $cmd" >&2
        fail=1
      fi
    done
    for cmd in "''${allowed[@]}"; do
      got="$(decision "$cmd")"
      if [ "$got" != "none" ]; then
        echo "FAIL: expected no decision, got '$got' for: $cmd" >&2
        fail=1
      fi
    done

    for bad in 'not json at all' '{}' '{"tool_input":{}}'; do
      got=""
      got="$(printf '%s' "$bad" | "$guard" 2> /dev/null)"
      rc=$?
      if [ "$rc" -ne 0 ] || [ -n "$got" ]; then
        echo "FAIL: malformed event must exit 0 with no decision: $bad" >&2
        echo "  rc=$rc output=$got" >&2
        fail=1
      fi
    done

    if [ "$fail" -ne 0 ]; then
      echo "The guard is the only mechanical floor under the Bash tool." >&2
      exit 1
    fi
    echo "OK: ''${#denied[@]} denied, ''${#allowed[@]} allowed, 3 malformed" | tee "$out"
  ''
