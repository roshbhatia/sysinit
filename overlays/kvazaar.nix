_final: prev: {
  kvazaar =
    if prev.stdenv.hostPlatform.isDarwin then
      prev.kvazaar.overrideAttrs (_: {
        doCheck = false;
      })
    else
      prev.kvazaar;
  chromaprint =
    if prev.stdenv.hostPlatform.isDarwin then
      prev.chromaprint.overrideAttrs (_: {
        doCheck = false;
      })
    else
      prev.chromaprint;
}
