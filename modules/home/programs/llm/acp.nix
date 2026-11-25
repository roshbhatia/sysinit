{
  config,
  lib,
  pkgs,
  ...
}:
let
  acp = import ./lib/acp.nix { inherit lib; };
in
{
  xdg.configFile."acp/agents.json".source = pkgs.sysinit.writeJSON "llm-acp.json" {
    agent_servers = acp.formatAsAgentServers (
      acp.servers
      // {
        goose = acp.servers.goose // {
          command = "${config.home.profileDirectory}/bin/${acp.servers.goose.command}";
        };
      }
    );
  };
}
