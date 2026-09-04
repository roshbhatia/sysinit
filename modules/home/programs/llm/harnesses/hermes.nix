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
    mcp_servers = llmLib.mcp.formatForHermes (kit.mcpServers.serversFor "hermes");

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

  # _config_version is deliberately not declared here. hermes owns it: a
  # migration moves keys as well as bumping the number, so pinning 38 in Nix
  # would mark a config migrated that Nix never migrated, and would fight the
  # next bump. The reconciler preserves it as an undeclared key.
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
