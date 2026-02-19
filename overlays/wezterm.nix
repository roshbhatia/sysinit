{ ... }:

_final: prev:
let
  patch = [
    (prev.fetchpatch {
      url = "https://github.com/wezterm/wezterm/pull/7420.patch";
      hash = "sha256-feDJmnNje3LxJgsJJJmjKQHLBfaLFzTe4ErogrlOXiI=";
    })
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
