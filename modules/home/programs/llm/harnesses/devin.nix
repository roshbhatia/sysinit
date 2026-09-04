{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };

  devinGuardScript = llmLib.guards.mkExitCodeGuard {
    inherit pkgs;
    name = "devin-guard";
  };

  devinHooks = builtins.toJSON {
    PreToolUse = [
      {
        matcher = "exec";
        hooks = [
          {
            type = "command";
            command = "${lib.getExe devinGuardScript}";
          }
        ];
      }
    ];
  };

  devinSettings = {
    attribution = false;

    auto_update = false;

    read_config_from = {
      claude = false;
      cursor = false;
      windsurf = false;
    };

    permissions = {
      allow = llmLib.allowlist.formatForDevin (llmLib.allowlist.tierA ++ llmLib.allowlist.tierB);
      deny = llmLib.allowlist.formatDestructiveForDevin llmLib.allowlist.destructiveDenyGlobs;
      ask = [ ];
    };

  };
in
{

  sysinit.llm.managedFiles.devin = {
    path = ".config/devin/config.json";
    format = "json";
    content = devinSettings;
    enforce = [ "permissions" ];
  };

  # devin reads MCP from its own mcp_config.json, not from config.json. It
  # rewrites config.json on start and drops any mcpServers block there, so this
  # repo's catalog silently stopped reaching devin.
  sysinit.llm.managedFiles.devin-mcp = {
    path = ".config/devin/mcp_config.json";
    format = "json";
    content = {
      mcpServers = llmLib.mcp.formatForCursor (kit.mcpServers.serversFor "devin");
    };
    enforce = [ "mcpServers" ];
  };

  xdg.configFile = {
    "devin/AGENTS.md" = {
      text = kit.mkInstructionsWithStyle {
        harness = "devin";
        skillsRoot = "~/.config/devin/skills";
      };
      force = true;
    };

    "devin/hooks.v1.json" = {
      text = devinHooks;
      force = true;
    };
  };
}
