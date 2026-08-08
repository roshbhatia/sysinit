{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../../lib { inherit lib; };
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };

  exitCodeGuardScript = llmLib.guards.mkExitCodeGuard {
    inherit pkgs;
    name = "gemini-exit-code-guard";
  };

  agyHooks = builtins.toJSON {
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

  mcpConfigJson = builtins.toJSON {
    mcpServers = llmLib.mcp.formatForAntigravity kit.mcpServers.servers;
  };

  openspecPluginManifest = builtins.toJSON {
    name = "openspec-awareness";
    version = "1.0.0";
    description = "Surfaces the active OpenSpec change in conversation context so the agent knows what spec-driven work is in flight.";
    contextFileName = "CONTEXT.md";
    mcpServers = { };
  };

  importManifest = builtins.toJSON {
    imports = [
      {
        name = "openspec-awareness";
        source = "local-install";
        importedAt = "2026-06-26T00:00:00Z";
        components = [ "installed" ];
      }
    ];
  };
in
{
  home.file = {
    ".gemini/config/mcp_config.json" = {
      text = mcpConfigJson;
      force = true;
    };

    ".agents/AGENTS.md" = {
      text = kit.mkInstructionsWithStyle {
        harness = "gemini";
        skillsRoot = "~/.claude/skills";
      };
      force = true;
    };

    ".agents/hooks.json" = {
      text = agyHooks;
      force = true;
    };

    ".gemini/config/plugins/openspec-awareness/plugin.json" = {
      text = openspecPluginManifest;
      force = true;
    };
    ".gemini/config/plugins/openspec-awareness/CONTEXT.md" = {
      source = ./extensions/openspec-awareness/CONTEXT.md;
      force = true;
    };
    ".gemini/config/import_manifest.json" = {
      text = importManifest;
      force = true;
    };
  };

  home.packages = [ pkgs.antigravity-cli ];
}
