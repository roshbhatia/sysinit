{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };

  hermesSettings = {
    mcp_servers = llmLib.mcp.formatForHermes kit.mcpServers.servers;

    skills = {
      external_dirs = [ "${config.home.homeDirectory}/.claude/skills" ];

      creation_nudge_interval = 0;
    };

    security.tirith_enabled = false;

    telemetry.shared_metrics.enabled = false;
  };
in
{
  home.file.".hermes/SOUL.md" = {
    text = kit.mkInstructionsWithStyle {
      harness = "hermes";
      skillsRoot = "~/.claude/skills";
    };
    force = true;
  };

  sysinit.llm.managedFiles.hermes = {
    path = ".hermes/config.yaml";
    format = "yaml";
    content = hermesSettings;
    enforce = [
      [
        "skills"
        "external_dirs"
      ]
      [
        "skills"
        "creation_nudge_interval"
      ]
      [
        "security"
        "tirith_enabled"
      ]
      [
        "telemetry"
        "shared_metrics"
      ]
      [ "mcp_servers" ]
    ];
  };
}
