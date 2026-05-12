{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };
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
    };
  };
}
