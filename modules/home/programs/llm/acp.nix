{ lib, ... }:
let
  llmLib = import ./lib { inherit lib; };
in
{
  xdg.configFile."acp/agents.json".text = builtins.toJSON {
    agent_servers = llmLib.acp.formatAsAgentServers llmLib.acp.servers;
  };
}
