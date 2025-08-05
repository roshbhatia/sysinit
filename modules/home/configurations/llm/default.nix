{ lib, ... }:
{
  imports = [
    (import ./tools/aider.nix { inherit lib; })
    (import ./tools/goose.nix { inherit lib; })
    (import ./tools/opencode.nix { })
    (import ./tools/crush.nix { inherit lib; })
  ];
}
