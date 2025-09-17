{ lib, values, ... }:
let
  mcpServers = import ../shared/mcp-servers.nix;
  agents = import ../shared/agents.nix;
in
{
  xdg.configFile = {
    "goose/config.yaml" = {
      text = lib.generators.toYAML { } {
        ALPHA_FEATURES = true;
        EDIT_MODE = "vi";
        GOOSE_CLI_THEME = "ansi";
        GOOSE_PROVIDER = "github_copilot";
        GOOSE_LEAD_MODEL = values.llm.goose.leadModel;
        GOOSE_MODEL = "claude-sonnet-4";
        GOOSE_MODE = "smart_approve";
        GOOSE_RECIPE_GITHUB_REPO = "packit/ai-workflows";
        GOOSE_TEMPERATURE = 0.7;
        GOOSE_MAX_TOKENS = 8192;
        GOOSE_TIMEOUT = 300;
        # Sandbox-specific settings
        sandbox_mode = true;
        allow_sudo = true;
        disable_safety_checks = true;
        extensions =
          let
            builtinExtensions = {
              autovisualiser = {
                available_tools = [ ];
                bundled = true;
                description = null;
                display_name = "Auto Visualiser";
                enabled = true;
                name = "autovisualiser";
                timeout = 300;
                type = "builtin";
              };
              computercontroller = {
                bundled = true;
                display_name = "Computer Controller";
                enabled = true;
                name = "computercontroller";
                timeout = 300;
                type = "builtin";
              };
              developer = {
                bundled = true;
                display_name = "Developer";
                enabled = true;
                name = "developer";
                timeout = 300;
                type = "builtin";
              };
            };

            mcpExtensions = lib.mapAttrs (name: server: {
              args = server.args;
              bundled = null;
              cmd = server.command;
              description = server.description or "";
              enabled = server.enabled or true;
              env_keys = [ ];
              envs = server.env or { };
              name = lib.strings.toUpper (lib.substring 0 1 name) + lib.substring 1 (lib.stringLength name) name;
              timeout = 300;
              type = "stdio";
            }) mcpServers.servers;
          in
          builtinExtensions // mcpExtensions;
      };
      force = true;
    };
  }
  // builtins.listToAttrs (
    map (agent: {
      name = "goose/subagents/${agent.name}.yaml";
      value = {
        text = lib.generators.toYAML { } {
          id = agent.name;
          title = agent.name;
          description = agent.description;
          instructions = agent.instructions or "";
          activities = agent.activities or [ ];
          extensions = agent.extensions or [ ];
          parameters = agent.parameters or [ ];
          prompt = agent.prompt or "";
        };
      };
    }) agents
  );
}
