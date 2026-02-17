{
  lib,
  pkgs,
  config,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  mcpServers = import ../mcp.nix {
    inherit lib;
    additionalServers = config.sysinit.llm.mcp.additionalServers;
  };
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
    "$schema" = "https://charm.land/crush.json";
    mcp = formatMcpForCrush mcpServers.servers;
    tools = {
      ls = { };
      grep = { };
    };
    permissions = {
      allowed_tools = [
        "view"
        "beads"
        "openspec"
        "ls"
        "ripgrep"
        "fd"
        "ast-grep"
      ];
    };
    options = {
      disabled_tools = [
        "find"
        "grep"
      ];
      disable_metrics = true;
      attribution = {
        generated_with = false;
        trailer_style = "none";
      };
      initialize_as = "AGENTS.md";
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
