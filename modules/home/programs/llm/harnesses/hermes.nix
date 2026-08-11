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

    # tirith is a prebuilt binary from `sheeki03/tirith`, a personal GitHub
    # account, which hermes downloads unpinned from `releases/latest` into
    # `~/.hermes/bin/tirith` on a background thread at startup, then runs before
    # every shell command it executes. Two reasons that has to go rather than be
    # tolerated: the download is unpinned upstream content this repository never
    # declared, and `tirith_fail_open` defaults to true, so a spawn error or a
    # 5-second timeout allows the command anyway. It adds supply-chain surface
    # without being a gate you can rely on.
    #
    # This one key is the whole switch. `tools/tirith_security.py` opens its
    # resolve-and-install path with `if not cfg["tirith_enabled"]: return None`,
    # so the binary is neither fetched nor invoked. It is deliberately narrower
    # than `security.allow_lazy_installs`, which gates hermes' optional PyPI
    # backends and is a separate decision.
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
