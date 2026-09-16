{ pkgs }:
let
  inherit (pkgs) lib;
  tools =
    (import ../modules/home/programs/llm/lib/allowlist.nix { inherit (pkgs) lib; }).slackSendTools;
in
pkgs.runCommand "slack-guard-test"
  {
    nativeBuildInputs = [
      pkgs.bash
      pkgs.jq
    ];
    send_now_tools = builtins.toJSON (builtins.filter (t: !(lib.hasSuffix "schedule_message" t)) tools);
    schedule_tools = builtins.toJSON (builtins.filter (lib.hasSuffix "schedule_message") tools);
    allowed_channels = builtins.toJSON [ "U_ALLOWED" ];
  }
  ''
    for tool in ${lib.escapeShellArgs tools}; do
      for channel in U_ALLOWED U_OTHER; do
        result=$(jq -n --arg tool "$tool" --arg channel "$channel" \
          '{tool_name:$tool,tool_input:{channel_id:$channel}}' \
          | bash ${../modules/home/programs/llm/harnesses/claude/slack-guard.sh})
        if [[ "$tool" == *schedule_message || "$channel" == U_OTHER ]]; then
          jq -e '.hookSpecificOutput.permissionDecision == "deny"' <<< "$result"
        else
          test -z "$result"
        fi
      done
    done
    touch "$out"
  ''
