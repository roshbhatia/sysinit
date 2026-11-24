{ pkgs }:
let
  inherit (pkgs) lib;
  tools =
    (import ../../modules/home/programs/llm/lib/allowlist.nix { inherit (pkgs) lib; }).slackSendTools;
in
import ../lib/nushell.nix { inherit pkgs; } {
  name = "slack-guard-test";
  script = ./slack-guard.nu;
  arguments = [
    ../../modules/home/programs/llm/harnesses/claude/slack-guard.sh
    (pkgs.writeText "slack-guard-tools.json" (builtins.toJSON tools))
  ];
  inputs = [
    pkgs.bash
    pkgs.jq
  ];
  environment = {
    send_now_tools = builtins.toJSON (builtins.filter (t: !(lib.hasSuffix "schedule_message" t)) tools);
    schedule_tools = builtins.toJSON (builtins.filter (lib.hasSuffix "schedule_message") tools);
    allowed_channels = builtins.toJSON [ "U_ALLOWED" ];
  };
}
