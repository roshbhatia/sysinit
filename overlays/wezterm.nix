{ ... }:

_final: prev:
let
  # Try only the local cursor trail patch - upstream PR patch fails to apply
  patch = [
    ./wezterm-cursor-trail.patch
  ];
in
{
  wezterm = prev.wezterm.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ patch;
  });
}
// prev.lib.optionalAttrs (prev ? "wezterm-nightly") {
  "wezterm-nightly" = prev."wezterm-nightly".overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ patch;
  });
}
