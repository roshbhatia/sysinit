{ lib, pkgs, ... }:
let
  llmLib = import ./lib { inherit lib; };
in
{
  xdg.configFile."acp/agents.json".source = pkgs.sysinit.writeJSON "llm-acp.json" {
    agent_servers = llmLib.acp.formatAsAgentServers llmLib.acp.servers;
  };
}
