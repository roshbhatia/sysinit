{ lib }:
{
  mcp = import ./mcp.nix { inherit lib; };
  instructions = import ./instructions.nix;
  harnessKit = import ./harness-kit.nix;
  allowlist = import ./allowlist.nix { inherit lib; };
}
