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
    mcp = llmLib.mcp.formatForCrush kit.mcpServers.servers;
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
    # Ollama local provider — discovers all pulled models automatically.
    # Switch with Ctrl+L → select "ollama" provider.
    providers = {
      ollama = {
        name = "Ollama (local)";
        base_url = "http://localhost:11434/v1/";
        type = "ollama";
        discover_models = true;
      };
    };
    tools = {
      ls = { };
      grep = { };
    };
    # Allow all tool classes — crush uses class names, not bash patterns.
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
