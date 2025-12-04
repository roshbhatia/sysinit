# LLM Configuration Module
#
# This module configures various AI/LLM tools and their integrations:
# - Claude Desktop with MCP servers
# - GitHub Copilot CLI
# - Cursor AI editor with shell permissions
# - Goose AI assistant
# - OpenCode IDE with MCP integration
# - Amp editor with AI features
#
# Each sub-module handles specific tool configuration including:
# - MCP server definitions and formatting
# - Shell command permissions and security
# - Prompt management and agent configurations
# - Tool-specific settings and optimizations
{
  ...
}:
{
  imports = [
    ./config/amp.nix # Amp editor AI configuration
    ./config/claude.nix # Claude Desktop with MCP servers
    ./config/copilot.nix # GitHub Copilot CLI setup
    ./config/cursor.nix # Cursor AI with shell permissions
    ./config/goose.nix # Goose AI assistant configuration
    ./config/opencode.nix # OpenCode IDE with MCP integration
  ];
}
