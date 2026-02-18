{ ... }:

_final: prev: {
  wezterm = prev.wezterm.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      (prev.fetchpatch {
        url = "https://github.com/wezterm/wezterm/pull/7420.patch";
        hash = "sha256-08jy9swq5s2aw3g385wbyq2wn099lfcj828b4vqp4yv3ffdckq3x";
      })
      ./wezterm-cursor-trail.patch
    ];
  });
}
