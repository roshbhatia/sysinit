{ lib, ... }:
let
  llmLib = import ./lib { inherit lib; };

  agentServers = llmLib.acp.formatAsAgentServers llmLib.acp.servers;

  registry = import ./harnesses/registry.nix;

  # One generated list of who the agents are, so a reader does not keep its own
  # copy. neovim/config/lua/harness/launch.lua was that second copy, and it drifted:
  # it hard-coded fourteen names in load order and a command per adapter file.
  agents = lib.mapAttrsToList (name: h: {
    inherit name;
    inherit (h)
      label
      glyph
      command
      acp
      ;
  }) registry;
in
{
  xdg.configFile."acp/agents.json".text = builtins.toJSON {
    agent_servers = agentServers;
  };

  xdg.configFile."sysinit/agents.json".text = builtins.toJSON {
    version = 1;
    agents = lib.sort (a: b: a.name < b.name) agents;
  };
}
