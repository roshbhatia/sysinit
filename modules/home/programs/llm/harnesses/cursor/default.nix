{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../../lib { inherit lib; };
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };

  profileBin = "${config.home.profileDirectory}/bin";

  # cursor sends beforeShellExecution as {command, cwd}, where the claude wire
  # gate reads is {tool_name, tool_input.command}. The rename is the whole
  # adapter: bash-guard matches `^Bash$`, so an unrenamed payload matches
  # nothing and every destructive command reads as a pass.
  #
  # The reply travels as an exit status. cursor does translate claude's
  # hookSpecificOutput, but only on its own `preToolUse` step, so a claude-shaped
  # deny on this step is read as no decision and the command goes to cursor's
  # own approval prompt instead.
  shellGuardScript = pkgs.writeShellApplication {
    name = "cursor-gate-shell-guard";
    runtimeInputs = [ pkgs.jq ];
    text = ''
      ${llmLib.guards.gateStateDir}
      payload=$(jq -c '. + { tool_name: "Bash", tool_input: { command: (.command // "") } }')
      status=0
      ${lib.getExe pkgs.gate-cli} hook --harness claude --event PreToolUse --format exit-code \
        <<< "$payload" || status=$?
      # A pass prints nothing, which cursor reads as invalid JSON and, under
      # failClosed, as a block. A deny is exit 2 and never reaches this line.
      [ "$status" -ne 0 ] || printf '{}\n'
      exit "$status"
    '';
  };

  # A user hook runs from ~/.cursor, not from the workspace, so anything that
  # resolves a repository from its working directory needs the workspace cursor
  # puts in the environment.
  inWorkspace = command: ''cd "''${CURSOR_PROJECT_DIR:-$PWD}" && ${command}'';

  cursorHooks = {
    version = 1;
    hooks = {
      beforeShellExecution = [
        {
          command = lib.getExe shellGuardScript;
          timeout = 10;
          # A guard that fails open is the hole it exists to close.
          failClosed = true;
        }
      ];
      beforeSubmitPrompt = [
        { command = inWorkspace "${profileBin}/agent-state cursor working submit"; }
        { command = inWorkspace "${profileBin}/agent-edit-event cursor --prompt"; }
      ];
      afterFileEdit = [
        { command = inWorkspace "${profileBin}/agent-edit-event cursor"; }
      ];
      stop = [
        {
          command = inWorkspace ''${profileBin}/agent-notify cursor done ${profileBin}/agent-focus "" "$PWD"'';
        }
        { command = inWorkspace ''${profileBin}/agent-state cursor done "your move"''; }
      ];
      sessionEnd = [
        { command = inWorkspace "${profileBin}/agent-state cursor exit"; }
        { command = inWorkspace "${profileBin}/worklog"; }
      ];
    };
  };

  cursorSettings = {
    version = 1;
    permissions = {
      allow = [ "Shell(.*)" ];
      deny = llmLib.allowlist.formatDestructiveForCursor llmLib.allowlist.destructiveDenyGlobs;
    };
    editor = {
      vimMode = true;
    };
    network = {
      useHttp1ForAgent = true;
    };
  };

  cursorMcpConfig = builtins.toJSON {
    mcpServers = llmLib.mcp.formatForCursor (kit.mcpServers.serversFor "cursor");
  };

  alwaysMdc = pkgs.writeText "cursor-always.mdc" ''
    ---
    description: Repo-wide conventions and prohibitions, generated from instructions.nix.
    alwaysApply: true
    ---

    ${kit.mkInstructionsWithStyle {
      harness = "cursor";
      skillsRoot = "~/.claude/skills";
    }}
  '';

  cursorRules = {
    nix = ./rules/nix.mdc;
    markdown = ./rules/markdown.mdc;
  };

  # managedFiles paths are relative to the home directory.
  cursorConfigDir = "${lib.removePrefix "${config.home.homeDirectory}/" config.xdg.configHome}/cursor";

  ruleFiles = lib.mapAttrs' (
    name: path:
    lib.nameValuePair ".cursor/rules/${name}.mdc" {
      source = path;
      force = true;
    }
  ) cursorRules;

in
{

  # cursor-agent resolves its config dir as CURSOR_CONFIG_DIR, then
  # $XDG_CONFIG_HOME/cursor, then ~/.cursor, with no platform gate. This repo
  # exports XDG_CONFIG_HOME, so the second branch always wins and a file under
  # ~/.cursor is never read: the deny list here was inert. `rules/`,
  # `mcp.json` and `hooks.json` stay below, because cursor reads those from the
  # home directory rather than from the config dir.
  sysinit.llm.managedFiles.cursor = {
    path = "${cursorConfigDir}/cli-config.json";
    format = "json";
    content = cursorSettings;
    enforce = [ "permissions" ];
  };
  home.file = {
    ".cursor/rules/always.mdc" = {
      source = alwaysMdc;
      force = true;
    };
    ".cursor/mcp.json" = {
      text = cursorMcpConfig;
      force = true;
    };
    ".cursor/hooks.json" = {
      text = builtins.toJSON cursorHooks;
      force = true;
    };
  }
  // ruleFiles;
}
