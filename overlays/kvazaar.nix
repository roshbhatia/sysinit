_:

final: prev: {
  # CTest suites OOM-killed on aarch64-darwin in nixpkgs-unstable
  kvazaar = prev.kvazaar.overrideAttrs (_: {
    doCheck = false;
  });
  chromaprint = prev.chromaprint.overrideAttrs (_: {
    doCheck = false;
  });
}
