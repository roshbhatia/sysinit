{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };

  # Keep this list for confirmed per-harness incompatibilities only.
  disabledMcpServers = [ "slack" ];

  # The schemas ship inside the installed derivation, so a version bump moves
  # the binary and its schema together and a key move fails validation on the
  # bump itself. Do not vendor a copy: it would need its own drift check.
  schemaDir = "${render.schemas}";

  # Skills install only to ~/.claude/skills (per default.nix); opencode reads
  # that tree natively. Point instructions at the populated root, not a phantom
  # per-tool dir that holds no SKILL.md files.
  defaultInstructions =
    kit.mkInstructions {
      harness = "opencode";
      skillsRoot = "~/.claude/skills";
    }
    + ''

      ## OpenCode-specific Slack access

      OpenCode's MCP client does not support Slack's dynamic auth flow. If you
      need Slack context or need to send a Slack message, ask Claude Code to do
      it with `claude -p '<your Slack task>'` because Claude has Slack MCP
      access configured.
    ''
    + "\n## Output Style\n\n"
    + kit.llmLib.instructions.outputStyleRules;

  render = import ./opencode-render.nix { inherit pkgs lib; };

  opencodeConfig = render.main // {
    mcp = llmLib.mcp.formatForOpencode disabledMcpServers kit.mcpServers.servers;

  };

  subagentFiles = lib.mapAttrs' (
    name: agentConfig:
    lib.nameValuePair "opencode/agent/${name}.md" {
      text = llmLib.instructions.formatSubagentAsMarkdown {
        inherit name;
        config = agentConfig;
        harness = "opencode";
      };
    }
  ) llmLib.instructions.subagentDefs;

  # opencode.json must be a mutable file (not a Nix-store symlink) so OpenCode
  # can write plugin installation state back on first startup.  Deep-merge on
  # every activation. Nix wins for every declared key, and the blocks named in
  # `render.authoritative` are replaced wholesale rather than deep-merged, so a
  opencodeConfigFile = pkgs.writeText "opencode-base.json" (builtins.toJSON opencodeConfig);

  # OpenCode 1.18 moved the terminal-interface settings into their own file and
  # made opencode.json reject unknown keys (`additionalProperties: false` on the
  # Config definition). Writing them into the main file made OpenCode migrate
  # them out on every start and leave a .tui-migration.bak behind each time.
  opencodeTuiFile = pkgs.writeText "opencode-tui-base.json" (builtins.toJSON render.tui);

  updateOpencodeConfig = pkgs.writeShellScript "update-opencode-config" ''
    set -euo pipefail
    target="$HOME/.config/opencode/opencode.json"
    tui="$HOME/.config/opencode/tui.json"
    mkdir -p "$(dirname "$target")"

    for f in "$target" "$tui"; do
      if [ -L "$f" ]; then
        rm -f "$f"
      fi
    done

    tmp="$(mktemp "$target.tmp.XXXXXX")"
    tui_tmp="$(mktemp "$tui.tmp.XXXXXX")"
    trap 'rm -f "$tmp" "$tui_tmp"' EXIT

    if [ -f "$target" ]; then
      # Delete the retired keys BEFORE merging. A deep merge preserves any key
      # present in the live file, so dropping them from the Nix side alone is a
      # no-op against the running harness.
      ${pkgs.jq}/bin/jq -s ${lib.escapeShellArg (render.mergeProgram render.retiredMain)} "$target" ${opencodeConfigFile} > "$tmp"
    else
      cp ${opencodeConfigFile} "$tmp"
    fi

    if [ -f "$tui" ]; then
      ${pkgs.jq}/bin/jq -s ${lib.escapeShellArg (render.mergeProgram render.retiredTui)} "$tui" ${opencodeTuiFile} > "$tui_tmp"
    else
      cp ${opencodeTuiFile} "$tui_tmp"
    fi

    # Validate what OpenCode will actually read, not just the Nix base. A build
    # check cannot see this file: it is hermetic and this path is in $HOME.
    for pair in "$tmp:${schemaDir}/config.json" "$tui_tmp:${schemaDir}/tui.json"; do
      f="''${pair%%:*}"
      s="''${pair##*:}"
      if ! ${pkgs.check-jsonschema}/bin/check-jsonschema --schemafile "$s" "$f" > /dev/null 2>&1; then
        echo "opencode: merged config failed schema validation against $s" >&2
        ${pkgs.check-jsonschema}/bin/check-jsonschema --schemafile "$s" "$f" >&2 || true
        exit 1
      fi
    done

    mv "$tmp" "$target"
    mv "$tui_tmp" "$tui"
    chmod u+w "$target" "$tui"
  '';
in
{
  home.activation.opencodeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD ${updateOpencodeConfig}
  '';

  xdg.configFile = lib.mkMerge [
    {
      "opencode/plugin/sysinit-notify.ts" = {
        source = ./plugins/sysinit-notify.ts;
        force = true;
      };
      "opencode/AGENTS.md" = {
        text = defaultInstructions;
        force = true;
      };
    }
    subagentFiles
  ];

  home.packages = [ pkgs.opencode ];
}
