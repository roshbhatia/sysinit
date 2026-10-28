{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };

  copilotSettings = {
    banner = "never";
    renderMarkdown = true;
    screenReader = false;
    theme = "default";
    autoUpdate = false;
    hooks.PreToolUse = [
      {
        type = "command";
        command = lib.getExe exitCodeGuardScript;
        matcher = "Bash";
        timeoutSec = 15;
      }
    ];
  };

  copilotMcpConfig = builtins.toJSON {
    mcpServers = llmLib.mcp.formatForCopilot (kit.mcpServers.serversFor "copilot");
  };

  exitCodeGuardScript = llmLib.guards.mkGateHookScript {
    inherit pkgs;
    name = "copilot-gate-hook";
    harness = "copilot";
    event = "PreToolUse";
    format = "exit-code";
  };

in
{

  sysinit.llm.managedFiles.copilot = {
    path = ".copilot/settings.json";
    format = "json";
    content = copilotSettings;

    enforce = [
      "autoUpdate"
      [
        "hooks"
        "PreToolUse"
      ]
    ];
  };

  home.file = {

    ".copilot/mcp-config.json" = {
      text = copilotMcpConfig;
      force = true;
    };

    ".copilot/copilot-instructions.md" = {
      text = kit.mkInstructionsWithStyle {
        harness = "copilot";
        skillsRoot = "~/.copilot/skills";
      };
      force = true;
    };
  };
}
