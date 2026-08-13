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
      # Read in place rather than rendered a second time: hermes scans an
      # external dir for `<name>/SKILL.md`, which is already the layout
      # `skills/render.nix` writes under `~/.claude/skills`.
      external_dirs = [ "${config.home.homeDirectory}/.claude/skills" ];

      # Upstream's default is 15, which reminds the model to save a new skill every 15
      # tool-calling iterations.
      creation_nudge_interval = 0;
    };

    # tirith is a prebuilt binary from `sheeki03/tirith`, a personal GitHub account,
    # which hermes downloads unpinned from `releases/latest` into `~/.hermes/bin/tirith`
    # on a background thread at startup, then runs before every shell command it
    # executes.
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
      # Narrow on purpose. Enforcing `security` whole would strip
      # `acked_advisories`, which records advisories the owner has read and acted
      # on, and hermes writes it back only when a new one appears.
      [
        "security"
        "tirith_enabled"
      ]
      [
        "telemetry"
        "shared_metrics"
      ]
      # The catalog owns the whole map, not just the names this host suppresses.
      [ "mcp_servers" ]
    ];
  };
}
