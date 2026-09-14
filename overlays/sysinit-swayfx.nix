{
  inputs,
  ...
}:

# swayfx wrapped by the nixpkgs sway wrapper, which is what the NixOS host
# installs. It lived in modules/nixos/desktop/sway.nix, where no attribute
# named it and `cacheAttrs` could not reach it. Its source build is 1298
# derivations, and the input tracks master.
_final: prev:
prev.lib.optionalAttrs prev.stdenv.hostPlatform.isLinux {
  sysinit-swayfx = prev.sway.override {
    sway-unwrapped = inputs.swayfx.packages.${prev.stdenv.hostPlatform.system}.default;
  };
}
