{ lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options.sysinit.llm = {
    mcp = {
      disabledBuiltinServers = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          claude.ai built-in MCP server names to disable globally.
          Suppresses the "N servers need authentication" startup warning
          for integrations the user never uses.
          Names must match exactly (e.g. "claude.ai Airtable").
        '';
      };

      additionalServers = mkOption {
        type = types.attrsOf (
          types.submodule {
            options = {
              type = mkOption {
                type = types.enum [
                  "local"
                  "http"
                ];
                default = "local";
                description = "Transport type — stdio (`local`) or remote `http`.";
              };
              command = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Command to run the MCP server (stdio servers only).";
              };
              args = mkOption {
                type = types.listOf types.str;
                default = [ ];
                description = "Arguments to pass to the MCP server command";
              };
              url = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Remote endpoint URL (http servers only).";
              };
              headers = mkOption {
                type = types.attrsOf types.str;
                default = { };
                description = "Headers to send with each request (http servers only).";
              };
              env = mkOption {
                type = types.attrsOf types.str;
                default = { };
                description = "Environment variables for local stdio servers.";
              };
              enabled = mkOption {
                type = types.bool;
                default = true;
                description = "Whether the server should be enabled in harnesses that support per-server toggles.";
              };
              timeout = mkOption {
                type = types.nullOr types.int;
                default = null;
                description = "Optional server timeout in seconds for harnesses that support it.";
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
