{ lib }:
{
  acp = import ./acp.nix { inherit lib; };
  mcp = import ./mcp.nix { inherit lib; };
  vocab = import ./vocab.nix { inherit lib; };
  instructions = import ./instructions.nix { inherit lib; };
  harnessKit = import ./harness-kit.nix;
  allowlist = import ./allowlist.nix { inherit lib; };
  guards = import ./guards.nix { inherit lib; };
  commandPath = import ../../../../shared/command-path.nix { inherit lib; };
  managedFile = import ./managed-file.nix { inherit lib; };
}
