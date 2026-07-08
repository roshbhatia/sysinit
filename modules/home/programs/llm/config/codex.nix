{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };

  profileBin = "${config.home.profileDirectory}/bin";
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
    # Codex 0.134.0+ reads profiles from CODEX_HOME/<name>.config.toml, so these
    # live under `programs.codex.profiles` (not `settings.profiles`, removed).
    profiles = {
      default = {
        reasoning_effort = "low";
      };
      spec = {
        reasoning_effort = "high";
        model_reasoning_summary = "detailed";
      };
    };

    settings = {
      # Opt in to the experimental Streamable HTTP MCP client (v0.44.0+). Without
      # this, URL-based MCP entries in the TOML config are silently ignored.
      experimental_use_rmcp_client = true;

      # Lifecycle notifications via the shared agent-notify script. Codex exposes
      # no idle event, so the deterministic set is: PermissionRequest (waiting on
      # your approval) and Stop (turn finished). Serializes to [[hooks.<Event>]].
      # Hook commands intentionally use stable Home Manager profile paths instead
      # of derivation-specific /nix/store paths so Codex's hook-trust cache
      # survives rebuilds.
      hooks = {
        PermissionRequest = [
          {
            hooks = [
              {
                type = "command";
                command = "${profileBin}/agent-prompt codex approval ${profileBin}/agent-focus";
              }
              {
                type = "command";
                command = "${profileBin}/agent-state codex waiting message";
              }
            ];
          }
        ];
        Stop = [
          {
            hooks = [
              {
                type = "command";
                command = "${profileBin}/agent-notify codex done ${profileBin}/agent-focus";
              }
              {
                type = "command";
                command = "${profileBin}/agent-state codex done \"your move\"";
              }
            ];
          }
        ];
      };
    };
  };
}
