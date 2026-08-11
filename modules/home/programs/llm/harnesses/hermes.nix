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

      # Upstream's default is 15, which reminds the model to save a new skill
      # every 15 tool-calling iterations. Skill creation always writes to
      # `~/.hermes/skills`, never to an external dir, so the default grows a
      # second skill library that Nix does not declare and no switch reconciles.
      # That directory already holds 87 skill documents against the 69 this
      # repository renders.
      #
      # 0 disables the nudge. It does not stop the owner asking hermes to write a
      # skill, and it does not remove what is already there.
      creation_nudge_interval = 0;
    };

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
        "telemetry"
        "shared_metrics"
      ]
      # The catalog owns the whole map, not just the names this host suppresses.
      #
      # `hermes mcp add` and `hermes config set` rewrite config.yaml, so a server
      # dropped from the catalog is absent from the recorded base and the merge
      # keeps the on-disk entry. `retire` covered `suppressedServers` only, which
      # left every other undeclared name in place: this file carried `cocoindex`
      # and `incident-io` for the 41 days after 2026-07-01, when the host stopped
      # declaring them.
      #
      # Enforcing the map means a server added by `hermes mcp add` is dropped on
      # the next switch. That is the intended trade rather than a cost: a server
      # added by hand is hand-managed configuration where a Nix equivalent
      # exists, and `sysinit.llm.mcp.additionalServers` is where it belongs. The
      # alternative leaves silent drift that nothing reports.
      [ "mcp_servers" ]
    ];
  };
}
