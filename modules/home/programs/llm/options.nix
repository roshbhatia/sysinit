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
  };
}
