#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq git nodejs npm openssl

set -euo pipefail

echo "🚀 Setting up WithContext MCP server for Obsidian integration..."

# Configuration
VAULT_NAME="${OBSIDIAN_VAULT:-Main}"
PROJECT_BASE_PATH="${PROJECT_BASE_PATH:-Projects}"
API_URL="${OBSIDIAN_API_URL:-https://127.0.0.1:27124}"

# Generate API key if not exists
API_KEY_FILE="$HOME/.config/obsidian/api-key"
if [[ ! -f $API_KEY_FILE ]]; then
  echo "📋 Generating Obsidian API key..."
  mkdir -p "$(dirname "$API_KEY_FILE")"
  openssl rand -hex 32 > "$API_KEY_FILE"
  chmod 600 "$API_KEY_FILE"
  echo "✅ API key generated and stored at $API_KEY_FILE"
else
  echo "✅ API key already exists at $API_KEY_FILE"
fi

API_KEY=$(cat "$API_KEY_FILE")

# Install Obsidian Local REST API plugin
OBSIDIAN_CONFIG="$HOME/Library/Application Support/Obsidian"
PLUGINS_DIR="$OBSIDIAN_CONFIG/plugins"
REST_API_PLUGIN_DIR="$PLUGINS_DIR/obsidian-local-rest-api"

echo "🔌 Installing Obsidian Local REST API plugin..."
mkdir -p "$PLUGINS_DIR"

if [[ ! -d $REST_API_PLUGIN_DIR ]]; then
  cd "$PLUGINS_DIR"
  git clone "https://github.com/czottmann/obsidian-local-rest-api.git"
  cd "$REST_API_PLUGIN_DIR"
  npm install
  npm run build
  echo "✅ Plugin installed successfully"
else
  echo "✅ Plugin already installed"
fi

# Enable plugin in Obsidian configuration
CONFIG_FILE="$OBSIDIAN_CONFIG/obsidian.json"
if [[ -f $CONFIG_FILE ]]; then
  if ! jq -e '.enabledPlugins | contains(["obsidian-local-rest-api"])' "$CONFIG_FILE" > /dev/null; then
    echo "⚙️ Enabling Local REST API plugin in Obsidian configuration..."
    jq '.enabledPlugins += ["obsidian-local-rest-api"]' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
    echo "✅ Plugin enabled in configuration"
  else
    echo "✅ Plugin already enabled in configuration"
  fi
else
  echo "⚠️ Obsidian configuration file not found. Please enable the Local REST API plugin manually in Obsidian settings."
fi

# Add environment variables to shell profile
PROFILE_FILE="$HOME/.zshrc"
if ! grep -q "OBSIDIAN_API_KEY" "$PROFILE_FILE" 2> /dev/null; then
  echo "" >> "$PROFILE_FILE"
  echo "# WithContext MCP Server Environment Variables" >> "$PROFILE_FILE"
  echo "export OBSIDIAN_API_KEY=\"$API_KEY\"" >> "$PROFILE_FILE"
  echo "export OBSIDIAN_API_URL=\"$API_URL\"" >> "$PROFILE_FILE"
  echo "export OBSIDIAN_VAULT=\"$VAULT_NAME\"" >> "$PROFILE_FILE"
  echo "export PROJECT_BASE_PATH=\"$PROJECT_BASE_PATH\"" >> "$PROFILE_FILE"
  echo "✅ Environment variables added to $PROFILE_FILE"
else
  echo "✅ Environment variables already exist in $PROFILE_FILE"
fi

# Test API connection
echo "🔍 Testing Obsidian API connection..."
if curl -s -H "Authorization: Bearer $API_KEY" "$API_URL" > /dev/null 2>&1; then
  echo "✅ API connection successful"
else
  echo "⚠️ API connection failed. Please ensure:"
  echo "   1. Obsidian is running"
  echo "   2. Local REST API plugin is enabled"
  echo "   3. API is running on $API_URL"
fi

echo ""
echo "🎉 WithContext MCP server setup complete!"
echo ""
echo "Configuration:"
echo "  API Key: $API_KEY"
echo "  Vault: $VAULT_NAME"
echo "  API URL: $API_URL"
echo "  Project Base Path: $PROJECT_BASE_PATH"
echo ""
echo "Next steps:"
echo "  1. Restart your terminal or run: source ~/.zshrc"
echo "  2. Ensure Obsidian is running with Local REST API plugin enabled"
echo "  3. Apply Nix configuration: task nix:refresh"
echo "  4. Test with your AI client"
echo ""
echo "The with-context MCP server will now be available in your AI clients!"
