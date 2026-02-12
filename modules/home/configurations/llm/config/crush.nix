{
  lib,
  pkgs,
  values,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  mcpServers = import ../mcp.nix { inherit lib values; };
  skillsLib = import ../skills.nix { inherit pkgs; };

  defaultInstructions = llmLib.instructions.makeInstructions {
    inherit (skillsLib) localSkillDescriptions;
    skillsRoot = "~/.config/crush/skills";
  };

  formatMcpForCrush =
    servers:
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
    ) servers;

  crushSettings = {
    mcp = formatMcpForCrush mcpServers.servers;
    options = {
      initialize_as = "AGENTS.md";
      trailer_style = "none";
      generated_with = false;
      disable_metrics = true;
    };
  };

  crushConfig = builtins.toJSON crushSettings;
in
{
  xdg.configFile = {
    "crush/crush.json" = {
      text = crushConfig;
      force = true;
    };
    "crush/AGENTS.md" = {
      text = defaultInstructions;
      force = true;
    };
  };

  # home.packages = with pkgs; [
  #   crush
  # ];
}
