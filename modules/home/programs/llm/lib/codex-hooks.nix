{
  lib,
  pkgs,
  profileBin,
}:
let
  guards = import ./guards.nix { inherit lib; };
  preToolUse = guards.mkGateHookScript {
    inherit pkgs;
    name = "codex-gate-hook";
    harness = "codex";
    event = "PreToolUse";
  };
  gate =
    event:
    guards.mkGateHookScript {
      inherit pkgs event;
      name = "gate-hook-codex-${lib.toLower event}";
      harness = "codex";
    };
  commandHook = command: {
    type = "command";
    inherit command;
  };
in
{
  packages = [
    preToolUse
    (gate "PostToolUse")
    (gate "UserPromptSubmit")
  ];
  hooks = {
    PreToolUse = [ { hooks = [ (commandHook "${profileBin}/codex-gate-hook") ]; } ];
    PostToolUse = [ { hooks = [ (commandHook "${profileBin}/gate-hook-codex-posttooluse") ]; } ];
    UserPromptSubmit = [
      {
        hooks = [
          (commandHook "${profileBin}/agent-state codex working submit")
          (commandHook "${profileBin}/gate-hook-codex-userpromptsubmit")
        ];
      }
    ];
    Stop = [
      {
        hooks = [
          (commandHook "${profileBin}/agent-notify codex done ${profileBin}/agent-focus")
          (commandHook "${profileBin}/agent-state codex done \"your move\"")
        ];
      }
    ];
  };
}
