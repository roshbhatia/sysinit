{
  pkgs,
  values,
  lib,
  ...
}:
let
  cfg = values.llm.withContext or { };

  # Activation script for WithContext MCP server
  activationScript = pkgs.writeShellScript "with-context-activation" ''
    set -euo pipefail

    echo "Setting up WithContext MCP server for Obsidian integration..."

    # Configuration
    VAULT_NAME="''${OBSIDIAN_VAULT:-${
      lib.escapeShellArg (if cfg.vault or null != null then cfg.vault else "Main")
    }}"
    PROJECT_BASE_PATH="''${PROJECT_BASE_PATH:-${
      lib.escapeShellArg (if cfg.projectBasePath or null != null then cfg.projectBasePath else "Projects")
    }}"
    API_URL="''${OBSIDIAN_API_URL:-${
      lib.escapeShellArg (if cfg.apiUrl or null != null then cfg.apiUrl else "https://127.0.0.1:27124")
    }}"

    # Generate API key if not exists
    API_KEY_FILE="$HOME/.config/obsidian/api-key"
    if [[ ! -f "$API_KEY_FILE" ]]; then
      echo "Generating Obsidian API key..."
      mkdir -p "$(dirname "$API_KEY_FILE")"
      ${pkgs.openssl}/bin/openssl rand -hex 32 > "$API_KEY_FILE"
      chmod 600 "$API_KEY_FILE"
      echo "API key generated and stored at $API_KEY_FILE"
    else
      echo "API key already exists at $API_KEY_FILE"
    fi

    API_KEY=$(cat "$API_KEY_FILE")

    # Install Obsidian Local REST API plugin
    OBSIDIAN_CONFIG="$HOME/Library/Application Support/Obsidian"
    PLUGINS_DIR="$OBSIDIAN_CONFIG/plugins"
    REST_API_PLUGIN_DIR="$PLUGINS_DIR/obsidian-local-rest-api"

    echo "Installing Obsidian Local REST API plugin..."
    mkdir -p "$PLUGINS_DIR"

    if [[ ! -d "$REST_API_PLUGIN_DIR" ]]; then
      cd "$PLUGINS_DIR"
      ${pkgs.git}/bin/git clone "https://github.com/czottmann/obsidian-local-rest-api.git"
      cd "$REST_API_PLUGIN_DIR"
      ${pkgs.nodejs}/bin/npm install
      ${pkgs.nodejs}/bin/npm run build
      echo "Plugin installed successfully"
    else
      echo "Plugin already installed"
    fi

    # Enable plugin in Obsidian configuration
    CONFIG_FILE="$OBSIDIAN_CONFIG/obsidian.json"
    if [[ -f "$CONFIG_FILE" ]]; then
      if ! ${pkgs.jq}/bin/jq -e '.enabledPlugins | contains(["obsidian-local-rest-api"])' "$CONFIG_FILE" >/dev/null; then
        echo "Enabling Local REST API plugin in Obsidian configuration..."
        ${pkgs.jq}/bin/jq '.enabledPlugins += ["obsidian-local-rest-api"]' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
        echo "Plugin enabled in configuration"
      else
        echo "Plugin already enabled in configuration"
      fi
    else
      echo "Warning: Obsidian configuration file not found. Please enable Local REST API plugin manually in Obsidian settings."
    fi

    echo "Testing Obsidian API connection..."
    if ${pkgs.curl}/bin/curl -s -H "Authorization: Bearer $API_KEY" "$API_URL" >/dev/null 2>&1; then
      echo "API connection successful"
    fi

    echo ""
    echo "Configuration:"
    echo "  Vault: $VAULT_NAME"
    echo "  API URL: $API_URL"
    echo "  Project Base Path: $PROJECT_BASE_PATH"
    echo ""
  '';

in
{
  config = lib.mkIf (cfg.enable or false) {
    home.sessionVariables = {
      OBSIDIAN_API_KEY = if cfg.apiKey or null != null then cfg.apiKey else "";
      OBSIDIAN_API_URL = cfg.apiUrl or "https://127.0.0.1:27124";
      OBSIDIAN_VAULT = cfg.vault or "Default";
      PROJECT_BASE_PATH = cfg.projectBasePath or "Projects";
    };

    # Run activation script
    home.activation.withContext = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${activationScript}
    '';
  };
}
