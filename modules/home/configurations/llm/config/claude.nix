{ lib, values, ... }:
let
  mcpServers = import ../shared/mcp-servers.nix;
  claudeEnabled = values.llm.claude.enabled or false;
in
lib.mkIf claudeEnabled {
  home.file = {
    "claude/settings.json" = {
      text = builtins.toJSON {
        includeCoAuthoredBy = false;
        env = {
          CLAUDE_CODE_ENABLE_TELEMETRY = "1";
          OTEL_METRICS_EXPORTER = "otlp";
          NODE_TLS_REJECT_UNAUTHORIZED = "0";
        };
        inherit (mcpServers) servers;
      };
      force = true;
    };
  };
}
