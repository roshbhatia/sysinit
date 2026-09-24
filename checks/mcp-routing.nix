{ pkgs }:
let
  inherit (pkgs) lib;
  routeServer = import ../modules/home/programs/llm/lib/mcp-routing.nix { inherit lib pkgs; };
  catalog = import ../modules/home/programs/llm/lib/mcp-catalog.nix {
    inherit lib routeServer;
    additionalServers = {
      disabled = {
        command = "must-not-start";
        enabled = false;
      };
      workspace = {
        command = "fixture";
        args = [ "argument with spaces" ];
        env.ORC_SESSION_ID = "fixture-session";
      };
      remote = {
        type = "http";
        url = "https://example.com/mcp";
      };
      gateway = {
        type = "http";
        url = "http://127.0.0.1:18080/mcp";
        gateway = true;
      };
    };
  };
  mcp = import ../modules/home/programs/llm/lib/mcp.nix { inherit lib; };
  renderers = [
    mcp.formatForClaude
    mcp.formatForAmp
    mcp.formatForCursor
    mcp.formatForAntigravity
    mcp.formatForGoose
    mcp.formatForHermes
    mcp.formatForCopilot
    mcp.formatForCrush
    (mcp.formatForOpencode [ ])
  ];
  normalize = servers: servers.servers or servers;
  rendered = map (render: normalize (render catalog.servers)) renderers;
  names = [
    "gateway"
    "remote"
    "workspace"
  ];
in
assert builtins.all (servers: builtins.attrNames servers == names) rendered;
assert builtins.all (server: !(server ? url) && !(server ? serverUrl) && !(server ? uri)) (
  lib.concatMap builtins.attrValues rendered
);
assert builtins.all (server: lib.hasSuffix "sysinit-mcp-gateway" server.command) (
  builtins.attrValues catalog.servers
);
assert catalog.servers.workspace.env.ORC_SESSION_ID == "fixture-session";
pkgs.runCommand "mcp-client-routing" { } "touch $out"
