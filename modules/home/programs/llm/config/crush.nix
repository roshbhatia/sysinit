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
    # Two-tier split: Sonnet 5 is the mid-tier reasoner (near-Opus on coding and
    # agentic work at lower cost), with a Haiku-class helper for cheap
    # summarization/title work. `anthropic` is a built-in provider in Crush's
    # catalog, so no explicit providers block is needed.
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
    # Live nix diagnostics via nixd (full store path — no PATH dependency).
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
      text = kit.mkInstructionsWithStyle {
        harness = "crush";
        skillsRoot = "~/.claude/skills";
      };
      force = true;
    };
  };

  home.packages = [ pkgs.crush ];
}
