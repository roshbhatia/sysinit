{ lib, ... }:
{
  imports = [
    ./aider.nix
    (import ./tools/mcphub.nix { inherit lib; })
    (import ./tools/goose.nix { inherit lib; })
    (import ./tools/opencode.nix { })
    (import ./tools/crush.nix { inherit lib; })
    (import ./tools/litellm-proxy.nix { inherit lib; })
  ];
}

