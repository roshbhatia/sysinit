{ ... }:

final: prev:
let
  patch = [
    (prev.fetchpatch {
      url = "https://github.com/wezterm/wezterm/pull/7420.patch";
      hash = "sha256-08jy9swq5s2aw3g385wbyq2wn099lfcj828b4vqp4yv3ffdckq3x";
    })
    ./wezterm-cursor-trail.patch
  ];
in
{
  wezterm = prev.wezterm.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ patch;
  });
}
// final.lib.optionalAttrs (prev ? "wezterm-nightly") {
  "wezterm-nightly" = prev."wezterm-nightly".overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ patch;
  });
}
