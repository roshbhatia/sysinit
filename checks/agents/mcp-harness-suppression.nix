{ pkgs }:
let
  inherit (pkgs) lib;
  mcpCatalog = import ../../modules/home/programs/llm/lib/mcp-catalog.nix {
    inherit (pkgs) lib;
    additionalServers = {
      kept = {
        command = "kept";
        args = [ ];
      };
      suppressed = {
        command = "suppressed";
        args = [ ];
      };
    };
    harnessSuppressedServers.amp = [ "suppressed" ];
  };
  mcp = import ../../modules/home/programs/llm/lib/mcp.nix { inherit (pkgs) lib; };
  ampMcpServers = mcp.formatForAmp (mcpCatalog.serversFor "amp");
in
assert lib.assertMsg (
  ampMcpServers.kept.command == "kept"
) "the amp MCP set dropped the kept server";
assert lib.assertMsg (
  !(ampMcpServers ? suppressed)
) "the amp MCP set carries suppressed, which harnessSuppressedServers removes";
pkgs.runCommand "mcp-harness-suppression" { } "touch $out"
