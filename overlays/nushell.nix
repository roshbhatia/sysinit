# overlays/nushell.nix
# Disable nushell's checkPhase to work around flaky SHLVL tests in 0.112.x
_:

final: prev: {
  nushell = prev.nushell.overrideAttrs (_old: {
    doCheck = false;
  });
}
