{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  kit = llmLib.harnessKit.mkKit { inherit lib pkgs config; };

  # Antigravity CLI (`agy`) is the successor to the retired Gemini CLI. It is a
  # Go binary that still roots its data under ~/.gemini, but the config surface
  # moved off Gemini's TOML onto JSON. The shapes below were confirmed against
  # the built `antigravity-cli` 1.0.7 binary (see design.md Decision 6):
  #   - MCP:     ~/.gemini/config/mcp_config.json   ({ "mcpServers": { … } })
  #   - rules:   ~/.agents/AGENTS.md                 (Global Customizations Root)
  #   - plugins: ~/.gemini/config/plugins/<name>/    + import_manifest.json registry
  # agy reads AGENTS.md natively, so the per-tool GEMINI.md write is dropped.

  # agy's MCP file is standard Claude-shape JSON; formatForClaude already emits
  # the per-server entries ({command,args,env} / {type:"http",url}). agy ignores
  # the extra description/enabled keys (Go json drops unknown fields).
  mcpConfigJson = builtins.toJSON {
    mcpServers = llmLib.mcp.formatForClaude kit.mcpServers.servers;
  };

  # The openspec-awareness extension re-homes as an agy plugin. agy requires the
  # manifest be named `plugin.json` (the legacy `gemini-extension.json` key set
  # is otherwise compatible — `contextFileName` is honored) and a registry entry
  # in import_manifest.json; a bare file-drop is not loaded. `agy plugin install`
  # of a plugin.json dir records source="local-install"/components=["installed"],
  # which is replicated declaratively here (no curl-installer, no `agy install`).
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
        # Fixed stamp: declarative installs have no install-time clock, and the
        # value is registry metadata only (agy keys activation off the files).
        importedAt = "2026-06-26T00:00:00Z";
        components = [ "installed" ];
      }
    ];
  };
in
{
  home.file = {
    # MCP servers (JSON; replaces the old gemini/settings.toml [mcpServers]).
    ".gemini/config/mcp_config.json" = {
      text = mcpConfigJson;
      force = true;
    };

    # Global rules, read natively from agy's Global Customizations Root. Mirrors
    # the content the retired GEMINI.md carried. Skill references point at the
    # populated ~/.claude/skills root (same as the other harnesses).
    ".agents/AGENTS.md" = {
      text = kit.mkInstructions "~/.claude/skills";
      force = true;
    };

    # openspec-awareness plugin: manifest, context file, and registry entry.
    ".gemini/config/plugins/openspec-awareness/plugin.json" = {
      text = openspecPluginManifest;
      force = true;
    };
    ".gemini/config/plugins/openspec-awareness/CONTEXT.md" = {
      source = ./gemini-extensions/openspec-awareness/CONTEXT.md;
      force = true;
    };
    ".gemini/config/import_manifest.json" = {
      text = importManifest;
      force = true;
    };
  };

  home.packages = [ pkgs.antigravity-cli ];
}
