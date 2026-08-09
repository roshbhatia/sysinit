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

    mcpServers = llmLib.mcp.formatForCursor kit.mcpServers.servers;
  };
in
{

  sysinit.llm.managedFiles.devin = {
    path = ".config/devin/config.json";
    format = "json";
    content = devinSettings;
    enforce = [ "permissions" ];
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
