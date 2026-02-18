# overlays/karabiner-elements.nix
# Purpose: pin karabiner-elements version.
{ ... }:

_final: prev: {
  karabiner-elements = prev.karabiner-elements.overrideAttrs (old: {
    version = "14.13.0";
    src = prev.fetchurl {
      inherit (old.src) url;
      hash = "sha256-gmJwoht/Tfm5qMecmq1N6PSAIfWOqsvuHU8VDJY8bLw=";
    };
  });
}
