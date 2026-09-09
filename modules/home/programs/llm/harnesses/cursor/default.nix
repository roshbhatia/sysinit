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
  worklogHook = llmLib.worklog.mkHook { inherit pkgs config; };

  # gate v0.2.5 speaks cursor natively: `--harness cursor` maps
  # beforeShellExecution onto PreToolUse with tool Bash and Input {command}, and
  # `--format cursor` answers in cursor's own permission vocabulary at exit 0.
  # No --event: the normalizer keys on the payload's hook_event_name, and a
  # passed event would arrive before that mapping runs.
  shellGuardScript = pkgs.writeShellApplication {
    name = "cursor-gate-shell-guard";
    text = ''
      ${llmLib.guards.gateStateDir}
      exec ${lib.getExe pkgs.gate-cli} hook --harness cursor --format cursor
    '';
  };

  # The same dispatcher for the hooks that only record: gate's cursor
  # normalizer maps afterFileEdit onto PostToolUse with tool Edit and
  # beforeSubmitPrompt onto UserPromptSubmit, and takes the workspace from the
  # payload, so neither needs the cd below.
  gateHookScript = pkgs.writeShellApplication {
    name = "cursor-gate-hook";
    text = ''
      ${llmLib.guards.gateStateDir}
      exec ${lib.getExe pkgs.gate-cli} hook --harness cursor --format cursor
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
        { command = lib.getExe gateHookScript; }
      ];
      afterFileEdit = [
        { command = lib.getExe gateHookScript; }
      ];
      stop = [
        {
          command = inWorkspace ''${profileBin}/agent-notify cursor done ${profileBin}/agent-focus "" "$PWD"'';
        }
        { command = inWorkspace ''${profileBin}/agent-state cursor done "your move"''; }
      ];
      sessionEnd = [
        { command = inWorkspace "${profileBin}/agent-state cursor exit"; }
        { command = inWorkspace worklogHook; }
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
