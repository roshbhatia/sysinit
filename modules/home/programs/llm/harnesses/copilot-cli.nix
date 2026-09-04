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
    theme = "auto";
    autoUpdate = false;
  };

  copilotMcpConfig = builtins.toJSON {
    mcpServers = llmLib.mcp.formatForCopilot (kit.mcpServers.serversFor "copilot");
  };

  exitCodeGuardScript = llmLib.guards.mkExitCodeGuard {
    inherit pkgs;
    name = "copilot-exit-code-guard";
  };

  # The store path is substituted rather than resolved from PATH, so a shadowed
  # binary cannot disarm the guard.
  copilotGuardExtension =
    builtins.replaceStrings
      [ "@guard@" ]
      [
        (lib.getExe exitCodeGuardScript)
      ]
      (builtins.readFile ./copilot/extensions/sysinit-guard/extension.mjs);
in
{

  sysinit.llm.managedFiles.copilot = {
    path = ".copilot/settings.json";
    format = "json";
    content = copilotSettings;

    enforce = [ "autoUpdate" ];
  };

  home.file = {
    # A user-scoped extension. Copilot scans this directory for immediate
    # subdirectories holding an extension.mjs, so the name of the directory is
    # the name of the extension.
    ".copilot/extensions/sysinit-guard/extension.mjs" = {
      text = copilotGuardExtension;
      force = true;
    };

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
