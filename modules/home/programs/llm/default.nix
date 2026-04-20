{ config, ... }:
{
  imports = [
    ./config/aider.nix
    ./config/amp.nix
    ./config/claude.nix
    ./config/codex.nix
    ./config/copilot-cli.nix
    ./config/crush.nix
    ./config/cursor.nix
    ./config/gemini.nix
    ./config/goose.nix
    ./config/mcp-servers.nix
    ./config/opencode.nix
    ./config/pi.nix
  ];

  programs.mcp = {
    enable = true;
    servers = config.sysinit.llm.mcp.additionalServers;
  };
}
