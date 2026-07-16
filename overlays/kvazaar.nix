_:

final: prev: {
  # CTest suites OOM-killed on aarch64-darwin in nixpkgs-unstable. Guard to
  # Darwin: on Linux these override the cached kvazaar/chromaprint, which
  # perturbs ffmpeg's closure and forces uncached source builds of everything
  # downstream (electron, webkitgtk, obsidian, lutris).
  kvazaar =
    if prev.stdenv.isDarwin then prev.kvazaar.overrideAttrs (_: { doCheck = false; }) else prev.kvazaar;
  chromaprint =
    if prev.stdenv.isDarwin then prev.chromaprint.overrideAttrs (_: { doCheck = false; }) else prev.chromaprint;
}
