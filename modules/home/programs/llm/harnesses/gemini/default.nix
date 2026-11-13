{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../../lib { inherit lib; };
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };

  exitCodeGuardScript = llmLib.guards.mkGateHookScript {
    inherit pkgs;
    name = "gemini-gate-hook";
    harness = "gemini";
    event = "PreToolUse";
    format = "exit-code";
  };

  agyHooks = builtins.toJSON {
    sysinit-destructive-guard = {
      PreToolUse = [
        {
          matcher = "run_command|bash|shell";
          hooks = [
            {
              type = "command";
              command = "${lib.getExe exitCodeGuardScript}";
            }
          ];
        }
      ];
    };
  };

  mcpConfigJson = builtins.toJSON {
    mcpServers = llmLib.mcp.formatForAntigravity (kit.mcpServers.serversFor "gemini");
  };

in
{
  sysinit.llm.managedFiles.antigravity-cli = {
    path = ".gemini/antigravity-cli/settings.json";
    format = "json";
    content = {
      editorMode = "vim";
      altScreenMode = "always";
      colorScheme = "terminal";
    };
  };

  home.file = {
    ".gemini/config/mcp_config.json" = {
      text = mcpConfigJson;
      force = true;
    };

    ".gemini/config/AGENTS.md" = {
      text = kit.mkInstructionsWithStyle {
        harness = "gemini";
        skillsRoot = "~/.claude/skills";
      };
      force = true;
    };

    ".gemini/config/hooks.json" = {
      text = agyHooks;
      force = true;
    };

  };

}
