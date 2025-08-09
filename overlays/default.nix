{ inputs, system, ... }:
[
  (import ./packages.nix { inherit inputs system; })
  (import ./goose-cli.nix)
  # Add missing ankiAddons structure to fix stylix issue
  (final: _prev: {
    ankiAddons = {
      recolor = {
        withConfig = _config: final.stdenv.mkDerivation {
          name = "anki-recolor-stub";
          phases = ["installPhase"];
          installPhase = "mkdir -p $out";
        };
      };
    };
  })
]
