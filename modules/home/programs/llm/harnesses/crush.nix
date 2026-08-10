{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };

  crushSettings = {
    "$schema" = "https://charm.land/crush.json";
    mcp = llmLib.mcp.formatForCrush (kit.mcpServers.serversFor "crush");
    models = {
      large = {
        model = "claude-sonnet-5";
        provider = "anthropic";
      };
      small = {
        model = "claude-haiku-4-5";
        provider = "anthropic";
      };
    };
    providers = {
      ollama = {
        name = "Ollama (local)";
        base_url = "http://localhost:11434/v1/";
        type = "ollama";
        discover_models = true;
      };
    };
    lsp = {
      nix = {
        command = "${pkgs.nixd}/bin/nixd";
        filetypes = [ ".nix" ];
        root_markers = [ "flake.nix" ];
      };
    };
    tools = {
      ls = { };
      grep = { };
    };
    permissions = {
      allowed_tools = [
        "bash"
        "edit"
        "write"
        "view"
        "patch"
        "openspec"
        "ls"
        "ripgrep"
        "fd"
        "ast-grep"
        "find"
        "grep"
        "glob"
        "mcp"
      ];
    };
    options = {
      disabled_tools = [ ];
      disable_metrics = true;
      attribution = {
        generated_with = false;
        trailer_style = "none";
      };
      initialize_as = "AGENTS.md";
      global_context_paths = [
        "~/.config/crush/AGENTS.md"
        "~/.config/crush/CRUSH.md"
        "~/.config/AGENTS.md"
      ];
    };
  };

in
{

  sysinit.llm.managedFiles.crush = {
    path = ".config/crush/crush.json";
    format = "json";
    content = crushSettings;
    enforce = [ "permissions" ];
  };
  xdg.configFile = {
    "crush/AGENTS.md" = {
      text = kit.mkInstructionsWithStyle {
        harness = "crush";
        skillsRoot = "~/.claude/skills";
      };
      force = true;
    };
  };

}
