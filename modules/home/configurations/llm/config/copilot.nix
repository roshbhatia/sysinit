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

{
  lib,
  pkgs,
  ...
}:
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

  # Source files in Nix store
  configSource = pkgs.writeText "copilot-cli-config" copilotCliConfig;
  mcpSource = pkgs.writeText "copilot-mcp-config" mcpConfig;

  # Activation script for all copilot config locations
  activationScript = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    # Helper function to install writable config
    install_copilot_config() {
      local source_file="$1"
      local dest_path="$2"
      local config_name="$3"
      
      $DRY_RUN_CMD mkdir -p "$(dirname "$dest_path")"
      if [[ -f "$dest_path" && ! -L "$dest_path" ]]; then
        if ! cmp -s "$source_file" "$dest_path"; then
          $DRY_RUN_CMD echo "Copilot $config_name source changed, backing up and updating"
          $DRY_RUN_CMD cp "$dest_path" "$dest_path.nix-prev"
          $DRY_RUN_CMD cp -f "$source_file" "$dest_path"
        fi
      else
        $DRY_RUN_CMD echo "Installing new writable copilot $config_name"
        if [[ -L "$dest_path" ]]; then
          $DRY_RUN_CMD rm "$dest_path"
        fi
        $DRY_RUN_CMD cp "$source_file" "$dest_path"
      fi
    }

    # Install CLI config to both locations
    install_copilot_config "${configSource}" "''${XDG_CONFIG_HOME:-$HOME/.config}/github-copilot/cli/config.json" "XDG CLI config"
    install_copilot_config "${configSource}" "$HOME/.copilot/config.json" "home CLI config"

    # Install MCP config to both locations
    install_copilot_config "${mcpSource}" "''${XDG_CONFIG_HOME:-$HOME/.config}/github-copilot/cli/mcp-config.json" "XDG MCP config"
    install_copilot_config "${mcpSource}" "$HOME/.copilot/mcp-config.json" "home MCP config"
  '';
in
{
  home.activation.copilotConfig = activationScript;
}
