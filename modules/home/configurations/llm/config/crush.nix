{
  lib,
  values,
  ...
}:
let
  skills = import ../skills.nix {
    inherit lib;
    pkgs = null;
  };
  instructions = (import ../instructions.nix).makeInstructions {
    inherit (skills) localSkillDescriptions remoteSkillDescriptions;
  };
  mcpServers = import ../mcp.nix { inherit lib values; };

  agentsMd = instructions;

  formatMcpForCrush =
    mcpServers:
    builtins.mapAttrs (
      _name: server:
      if (server.type or "local") == "http" then
        {
          type = "http";
          inherit (server) url;
        }
      else
        {
          type = "stdio";
          inherit (server) command;
          args = server.args or [ ];
        }
    ) mcpServers;

  crushSettings = {
    mcp = formatMcpForCrush mcpServers.servers;
  };

  crushConfig = builtins.toJSON crushSettings;
in
{
  xdg.configFile = {
    "crush/crush.json".text = crushConfig;
    "crush/AGENTS.md".text = agentsMd;
  };
}
