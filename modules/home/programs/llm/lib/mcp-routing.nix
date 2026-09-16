{ lib, pkgs }:
let
  bridge = pkgs.writeShellScript "sysinit-mcp-gateway" ''
    set -euo pipefail
    exec ${pkgs.sysinit-gotools}/bin/mcp-gateway \
      --gateway ${lib.getExe pkgs.agentgateway} \
      --proxy ${lib.getExe pkgs.mcp-remote-go} "$@"
  '';
in
name: server:
let
  definition = pkgs.writeText "mcp-${name}.json" (builtins.toJSON (server // { inherit name; }));
in
{
  command = toString bridge;
  args = [ (toString definition) ];
  env = server.env or { };
  enabled = server.enabled or true;
  description = server.description or "";
}
