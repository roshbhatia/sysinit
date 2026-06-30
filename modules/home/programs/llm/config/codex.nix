{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };

  notify = import ./notify.nix { inherit pkgs lib; };
in
{
  programs.codex = {
    enable = true;
    enableMcpIntegration = true;
    context = kit.mkInstructions "~/.claude/skills";

    # Per-profile reasoning_effort. Default is `low` for fast iteration;
    # the `spec` profile uses `high` + visible reasoning summaries for
    # openspec-heavy work.
    # Invoke with `codex --profile spec` (or `-p spec`).
    settings = {
      profiles = {
        default = {
          reasoning_effort = "low";
        };
        spec = {
          reasoning_effort = "high";
          model_reasoning_summary = "detailed";
        };
      };

      # Lifecycle notifications via the shared agent-notify script. Codex exposes
      # no idle event, so the deterministic set is: PermissionRequest (waiting on
      # your approval) and Stop (turn finished). Serializes to [[hooks.<Event>]].
      hooks = {
        PermissionRequest = [
          {
            hooks = [
              {
                type = "command";
                command = "${notify.exe} codex approval ${notify.focusExe}";
              }
              {
                type = "command";
                command = "${notify.stateExe} codex waiting message";
              }
            ];
          }
        ];
        Stop = [
          {
            hooks = [
              {
                type = "command";
                command = "${notify.exe} codex done ${notify.focusExe}";
              }
              {
                type = "command";
                command = "${notify.stateExe} codex done \"your move\"";
              }
            ];
          }
        ];
      };
    };
  };
}
