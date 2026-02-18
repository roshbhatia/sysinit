{ lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options.sysinit.llm = {
    mcp = {
      additionalServers = mkOption {
        type = types.attrsOf (
          types.submodule {
            options = {
              command = mkOption {
                type = types.str;
                description = "Command to run the MCP server";
              };
              args = mkOption {
                type = types.listOf types.str;
                default = [ ];
                description = "Arguments to pass to the MCP server command";
              };
              description = mkOption {
                type = types.str;
                default = "";
                description = "Description of the MCP server";
              };
            };
          }
        );
        default = { };
        description = "Additional Model Context Protocol servers";
      };
    };

    copilot = {
      banner = mkOption {
        type = types.enum [
          "always"
          "never"
          "auto"
        ];
        default = "never";
        description = "When to show the GitHub Copilot banner";
      };

      renderMarkdown = mkOption {
        type = types.bool;
        default = true;
        description = "Render markdown in responses";
      };

      screenReader = mkOption {
        type = types.bool;
        default = false;
        description = "Enable screen reader mode";
      };

      theme = mkOption {
        type = types.enum [
          "auto"
          "light"
          "dark"
        ];
        default = "auto";
        description = "Color theme for GitHub Copilot CLI";
      };

      trustedFolders = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "List of trusted folders for GitHub Copilot";
      };
    };
  };
}
