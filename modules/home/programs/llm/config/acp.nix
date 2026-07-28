{ lib, ... }:
let
  llmLib = import ../lib { inherit lib; };

  # No ACP client is installed yet. Writing the registry to a neutral path keeps
  # one source of truth for the adapter commands, so adding a client later is a
  # symlink or a jq read rather than a second hand-maintained list. The shape is
  # Zed's `agent_servers`, which the other ACP clients copy.
  agentServers = llmLib.acp.formatAsAgentServers llmLib.acp.servers;
in
{
  xdg.configFile."acp/agents.json".text = builtins.toJSON {
    agent_servers = agentServers;
  };
}
