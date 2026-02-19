{ ... }:

_final: prev:
let
  # Cursor trail patches from PR #6743
  # 1. Main feature (10 commits squashed)
  # 2. Pane Y-position fix for split panes
  patch = [
    ./wezterm-cursor-trail.patch
    ./wezterm-cursor-trail-pane-fix.patch
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
