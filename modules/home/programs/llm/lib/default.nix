{ lib }:
{
  acp = import ./acp.nix { inherit lib; };
  mcp = import ./mcp.nix { inherit lib; };
  vocab = import ./vocab.nix { inherit lib; };
  instructions = import ./instructions.nix { inherit lib; };
  harnessKit = import ./harness-kit.nix;
  allowlist = import ./allowlist.nix { inherit lib; };
}
