{ lib, ... }:
{
  imports = [
    (import ./tools/mcphub.nix { inherit lib; })
    (import ./tools/goose.nix { inherit lib; })
    (import ./tools/opencode.nix { inherit lib; })
    (import ./tools/crush.nix { inherit lib; })
  ];
}

