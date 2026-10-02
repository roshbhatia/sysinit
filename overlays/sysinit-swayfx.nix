{
  inputs,
  ...
}:

_final: prev:
prev.lib.optionalAttrs prev.stdenv.hostPlatform.isLinux {
  sysinit-swayfx = prev.sway.override {
    sway-unwrapped = inputs.swayfx.packages.${prev.stdenv.hostPlatform.system}.default;
  };
}
