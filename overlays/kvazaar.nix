_:

final: prev: {
  # kvazaar CTest suite fails on aarch64-darwin in nixpkgs-unstable
  kvazaar = prev.kvazaar.overrideAttrs (_: {
    doCheck = false;
  });
}
