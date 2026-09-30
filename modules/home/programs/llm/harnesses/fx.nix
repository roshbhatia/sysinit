{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };

  fxPermission = {
    "*" = "ask";
    read = "allow";
    list = "allow";
    glob = "allow";
    grep = "allow";
    edit = "allow";
    skill = "allow";
    web_fetch = "allow";

    bash = {
      "*" = "allow";
    }
    // (llmLib.allowlist.formatDestructiveForOpencode llmLib.allowlist.destructiveDenyGlobs);
  };
in
{
  home.file.".fx/mcp.json".source = pkgs.sysinit.writeJSON "harnesses-fx.json" {
    mcpServers = llmLib.mcp.formatForCursor (kit.mcpServers.serversFor "fx");
  };

  sysinit.llm.managedFiles.fx = {
    path = ".fx/settings.json";
    format = "json";
    content = {
      provider = "codex";
      models.codex = config.programs.codex.settings.model or "gpt-6-astra";
      permission_mode = "auto";
      permission = fxPermission;
    };
    enforce = [
      "provider"
      "permission"
    ];
  };

  home.file.".fx/AGENTS.md" = {
    text = kit.mkInstructionsWithStyle {
      harness = "fx";
      skillsRoot = "~/.claude/skills";
    };
    force = true;
  };
}
