{
  pkgs,
  values,
  lib,
  ...
}:
let
  cfg = values.llm.withContext or { };

  # Generate Obsidian API key if not provided
  generateApiKey = pkgs.writeShellScriptBin "generate-obsidian-api-key" ''
    set -euo pipefail

    API_KEY_FILE="$HOME/.config/obsidian/api-key"
    VAULT_NAME="''${OBSIDIAN_VAULT:-Default}"

    # Generate a secure random API key
    if [[ ! -f "$API_KEY_FILE" ]]; then
      echo "Generating Obsidian API key..."
      mkdir -p "$(dirname "$API_KEY_FILE")"
      openssl rand -hex 32 > "$API_KEY_FILE"
      chmod 600 "$API_KEY_FILE"
      echo "API key generated and stored at $API_KEY_FILE"
    else
      echo "API key already exists at $API_KEY_FILE"
    fi

    cat "$API_KEY_FILE"
  '';

  # Install Obsidian REST API plugin automatically
  installObsidianPlugin = pkgs.writeShellScriptBin "install-obsidian-rest-api" ''
    set -euo pipefail

    OBSIDIAN_CONFIG="$HOME/Library/Application Support/Obsidian"
    PLUGINS_DIR="$OBSIDIAN_CONFIG/plugins"
    REST_API_PLUGIN_DIR="$PLUGINS_DIR/obsidian-local-rest-api"

    # Create plugins directory if it doesn't exist
    mkdir -p "$PLUGINS_DIR"

    # Install plugin if not already installed
    if [[ ! -d "$REST_API_PLUGIN_DIR" ]]; then
      echo "Installing Obsidian Local REST API plugin..."
      cd "$PLUGINS_DIR"
      
      # Clone the plugin repository
      ${pkgs.git}/bin/git clone "https://github.com/czottmann/obsidian-local-rest-api.git"
      
      # Install dependencies
      cd "$REST_API_PLUGIN_DIR"
      ${pkgs.nodejs}/bin/npm install
      
      # Build the plugin
      ${pkgs.nodejs}/bin/npm run build
      
      echo "Plugin installed successfully"
    else
      echo "Plugin already installed"
    fi

    # Enable plugin in configuration
    CONFIG_FILE="$OBSIDIAN_CONFIG/obsidian.json"
    if [[ -f "$CONFIG_FILE" ]]; then
      # Check if plugin is already enabled
      if ! ${pkgs.jq}/bin/jq -e '.enabledPlugins | contains(["obsidian-local-rest-api"])' "$CONFIG_FILE" >/dev/null; then
        echo "Enabling Local REST API plugin in Obsidian configuration..."
        ${pkgs.jq}/bin/jq '.enabledPlugins += ["obsidian-local-rest-api"]' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
      fi
    fi
  '';

  # Setup script for with-context
  setupWithContext = pkgs.writeShellScriptBin "setup-with-context" ''
    set -euo pipefail

    echo "Setting up WithContext MCP server..."

    # Generate API key
    API_KEY=$(${generateApiKey}/bin/generate-obsidian-api-key)

    # Install Obsidian plugin
    ${installObsidianPlugin}/bin/install-obsidian-rest-api

    # Export environment variables
    export OBSIDIAN_API_KEY="$API_KEY"
    export OBSIDIAN_API_URL="''${OBSIDIAN_API_URL:-https://127.0.0.1:27124}"
    export OBSIDIAN_VAULT="''${OBSIDIAN_VAULT:-Default}"
    export PROJECT_BASE_PATH="''${PROJECT_BASE_PATH:-Projects}"

    echo "WithContext setup complete!"
    echo "API Key: $API_KEY"
    echo "Vault: $OBSIDIAN_VAULT"
    echo "API URL: $OBSIDIAN_API_URL"
    echo "Project Base Path: $PROJECT_BASE_PATH"

    # Add to shell profile if not already present
    PROFILE_FILE="$HOME/.zshrc"
    if ! grep -q "OBSIDIAN_API_KEY" "$PROFILE_FILE" 2>/dev/null; then
      echo "" >> "$PROFILE_FILE"
      echo "# WithContext MCP Server Environment Variables" >> "$PROFILE_FILE"
      echo "export OBSIDIAN_API_KEY=\"$API_KEY\"" >> "$PROFILE_FILE"
      echo "export OBSIDIAN_API_URL=\"$OBSIDIAN_API_URL\"" >> "$PROFILE_FILE"
      echo "export OBSIDIAN_VAULT=\"$OBSIDIAN_VAULT\"" >> "$PROFILE_FILE"
      echo "export PROJECT_BASE_PATH=\"$PROJECT_BASE_PATH\"" >> "$PROFILE_FILE"
      echo "Environment variables added to $PROFILE_FILE"
    fi
  '';

in
{
  home.packages = with pkgs; [
    nodejs
    npm
    generateApiKey
    installObsidianPlugin
    setupWithContext
  ];

  # Add with-context to additional packages if enabled
  config = lib.mkIf (cfg.enable or false) {
    home.packages = with pkgs; [
      nodePackages.with-context-mcp
    ];

    # Environment variables for with-context
    home.sessionVariables = {
      OBSIDIAN_API_KEY = cfg.apiKey or "";
      OBSIDIAN_API_URL = cfg.apiUrl or "https://127.0.0.1:27124";
      OBSIDIAN_VAULT = cfg.vault or "Default";
      PROJECT_BASE_PATH = cfg.projectBasePath or "Projects";
    };
  };
}
