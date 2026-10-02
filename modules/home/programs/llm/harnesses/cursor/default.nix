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

  shellGuardScript = pkgs.sysinit.writeShellApplication {
    name = "cursor-gate-shell-guard";
    text = ''
      ${llmLib.guards.gateStateDir}
      exec ${lib.getExe pkgs.gate-cli} hook --harness cursor --format cursor
    '';
  };

  gateHookScript = pkgs.sysinit.writeShellApplication {
    name = "cursor-gate-hook";
    text = ''
      ${llmLib.guards.gateStateDir}
      exec ${lib.getExe pkgs.gate-cli} hook --harness cursor --format cursor
    '';
  };

  inWorkspace = command: ''cd "''${CURSOR_PROJECT_DIR:-$PWD}" && ${command}'';

  cursorHooks = {
    version = 1;
    hooks = {
      beforeShellExecution = [
        {
          command = lib.getExe shellGuardScript;
          timeout = 10;

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
      source = pkgs.sysinit.writeJSON "cursor-default.json" cursorHooks;
      force = true;
    };
  }
  // ruleFiles;
}
