{ lib, ... }:
{
  imports = [
    ./tools/aider.nix
    ./tools/goose.nix
    ./tools/opencode.nix
    ./tools/crush.nix
  ];
}
