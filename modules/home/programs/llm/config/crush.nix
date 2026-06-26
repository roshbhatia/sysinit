{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };

  formatMcpForCrush =
    servers:
    builtins.mapAttrs (
      _name: server:
      if (server.type or "local") == "http" then
        {
          type = "http";
          inherit (server) url;
        }
      else
        {
          type = "stdio";
          inherit (server) command;
          args = server.args or [ ];
        }
    ) servers;

  crushSettings = {
    "$schema" = "https://charm.land/crush.json";
    mcp = formatMcpForCrush kit.mcpServers.servers;
    # Two-tier split: leave the strong reasoner as the default `large` model and
    # set a Haiku-class helper for cheap summarization/title work. Mirrors
    # aider.nix's architect + editor-model split. `anthropic` is a built-in
    # provider in Crush's catalog, so no explicit providers block is needed.
    models = {
      small = {
        model = "claude-haiku-4-5";
        provider = "anthropic";
      };
    };
    tools = {
      ls = { };
      grep = { };
    };
    # crush's `allowed_tools` are tool-class names (not bash patterns), so the
    # canonical Tier A allowlist doesn't apply directly here.
    permissions = {
      allowed_tools = [
        "view"
        "openspec"
        "ls"
        "ripgrep"
        "fd"
        "ast-grep"
      ];
    };
    options = {
      disabled_tools = [
        "find"
        "grep"
      ];
      disable_metrics = true;
      attribution = {
        generated_with = false;
        trailer_style = "none";
      };
      initialize_as = "AGENTS.md";
    };
  };

  crushConfig = builtins.toJSON crushSettings;
in
{
  xdg.configFile = {
    "crush/crush.json" = {
      text = crushConfig;
      force = true;
    };
    # Skills install only to ~/.claude/skills (per default.nix); Crush reads that
    # tree natively. Point instructions at the populated root, not a phantom
    # per-tool dir that holds no SKILL.md files.
    "crush/AGENTS.md" = {
      text = kit.mkInstructions "~/.claude/skills";
      force = true;
    };
  };

  home.packages = [ pkgs.crush ];
}
