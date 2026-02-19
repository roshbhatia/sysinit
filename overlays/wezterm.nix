{ ... }:

_final: prev:
let
  patch = [
    ./wezterm-webgpu-shaders.patch
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
