{ lib, values, ... }:
let
  mcpServers = import ../shared/mcp-servers.nix { inherit values; };
  common = import ../shared/common.nix;
  gooseEnabled = values.llm.goose.enabled or true;

  # Allow customizing goose settings via values
  gooseProvider = values.llm.goose.provider or "github_copilot";
  gooseModel = values.llm.goose.model or "claude-sonnet-4";
  goosePlannerProvider = values.llm.goose.plannerProvider or gooseProvider;
  goosePlannerModel = values.llm.goose.plannerModel or gooseModel;
in
lib.mkIf gooseEnabled {
  xdg.configFile = {
    "goose/config.yaml" = {
      text = lib.generators.toYAML { } {
        # Core Goose settings (GOOSE_* environment variables style)
        ALPHA_FEATURES = true;
        EDIT_MODE = "vi";
        GOOSE_CLI_THEME = "ansi";
        GOOSE_MAX_TOKENS = common.defaultModel.max_tokens;
        GOOSE_MODE = "smart_approve";
        GOOSE_MODEL = gooseModel;
        GOOSE_PLANNER_MODEL = goosePlannerModel;
        GOOSE_PLANNER_PROVIDER = goosePlannerProvider;
        GOOSE_PROVIDER = gooseProvider;
        GOOSE_RECIPE_GITHUB_REPO = "packit/ai-workflows";
        GOOSE_TEMPERATURE = common.defaultModel.temperature;
        GOOSE_TIMEOUT = common.defaultTimeout;

        # MCP extensions (the only other valid top-level field)
        extensions = common.gooseBuiltinExtensions // (common.formatMcpForGoose lib mcpServers.servers);
      };
      force = true;
    };
  };
}
