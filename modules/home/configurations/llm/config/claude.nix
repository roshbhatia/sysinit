{
  lib,
  values,
  ...
}:
let
  mcpServers = import ../shared/mcp-servers.nix { inherit values; };
  common = import ../shared/common.nix;
  claudeEnabled = values.llm.claude.enabled or true;
in
lib.mkIf claudeEnabled {
  home.file = {
    ".config/Claude/claude_desktop_config.json" = {
      text = builtins.toJSON {
        mcpServers = common.formatMcpForClaude mcpServers.servers;
      };
      force = true;
    };
  };
}
