{ lib }:
{
  mcp = import ./mcp.nix { inherit lib; };
  instructions = import ./instructions.nix;
}
