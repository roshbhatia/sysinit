# GitHub Copilot CLI Configuration
#
# This module configures GitHub Copilot CLI with:
#   - Shell command permissions
#   - MCP server configuration for extending capabilities
#
# The permissions are derived from the common shell permissions defined in
# modules/home/configurations/llm/shared/common.nix
#
# For more information:
#   - Run: copilot help permissions
#   - Run: copilot help config
#   - Docs: https://docs.github.com/en/copilot/using-github-copilot/using-github-copilot-cli
#
# Configuration locations:
#   - ~/.copilot/config.json
#   - ~/.copilot/mcp-config.json
#   - ~/.config/github-copilot/cli/config.json
#   - ~/.config/github-copilot/cli/mcp-config.json

{ ... }:
let
  common = import ../shared/common.nix;

  # Copilot CLI permissions configuration
  copilotCliConfig = builtins.toJSON {
    permissions = common.formatPermissionsForCopilotCli common.commonShellPermissions;
  };

  # MCP server configuration
  # To add custom MCP servers, configure them in the mcpServers object below.
  # Each MCP server should specify:
  #   - type: "local", "http", or "sse"
  #   - tools: array of tool names to enable (use ["*"] for all)
  #   - Additional keys based on type (command/args for local, url for remote)
  mcpConfig = builtins.toJSON {
    mcpServers = {
      # Built-in GitHub MCP server (enabled by default)
      # Uncomment and configure to customize with a personal access token
      # github-mcp-server = {
      #   type = "http";
      #   url = "https://api.githubcopilot.com/mcp/readonly";
      #   tools = ["*"];
      # };

      # Example: Sentry MCP server
      # sentry = {
      #   type = "local";
      #   command = "npx";
      #   args = ["@sentry/mcp-server@latest" "--host=$SENTRY_HOST"];
      #   tools = ["get_issue_details" "get_issue_summary"];
      #   env = {
      #     SENTRY_HOST = "https://contoso.sentry.io";
      #     SENTRY_ACCESS_TOKEN = "COPILOT_MCP_SENTRY_ACCESS_TOKEN";
      #   };
      # };
    };
  };
in
{
  # Permissions configuration
  xdg.configFile."github-copilot/cli/config.json" = {
    text = copilotCliConfig;
    force = true;
  };

  home.file.".copilot/config.json" = {
    text = copilotCliConfig;
    force = true;
  };

  # MCP server configuration
  xdg.configFile."github-copilot/cli/mcp-config.json" = {
    text = mcpConfig;
    force = true;
  };

  home.file.".copilot/mcp-config.json" = {
    text = mcpConfig;
    force = true;
  };
}
