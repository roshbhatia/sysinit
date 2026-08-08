{ lib, ... }:
let
  llmLib = import ./lib { inherit lib; };

  agentServers = llmLib.acp.formatAsAgentServers llmLib.acp.servers;
in
{
  xdg.configFile."acp/agents.json".text = builtins.toJSON {
    agent_servers = agentServers;
  };
}
