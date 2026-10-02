final: prev:
prev.lib.optionalAttrs prev.stdenv.hostPlatform.isDarwin {
  cua-driver = final.stdenvNoCC.mkDerivation {
    pname = "cua-driver";
    version = "0.30.4";
    src = final.fetchurl {
      url = "https://github.com/trycua/cua/releases/download/cua-driver-rs-v0.30.4/cua-driver-rs-0.30.4-darwin-arm64.tar.gz";
      hash = "sha256-4nDqZziNeUUFAxsKFdi1iZTGfhjnVKQ2NNdzIlH1ld8=";
    };
    dontFixup = true;
    installPhase = ''
      runHook preInstall
      mkdir -p "$out/Applications" "$out/bin"
      cp -R CuaDriver.app "$out/Applications/"
      ln -s "$out/Applications/CuaDriver.app/Contents/MacOS/cua-driver" "$out/bin/cua-driver"
      runHook postInstall
    '';
    meta = {
      description = "Native Cua computer-use driver";
      homepage = "https://github.com/trycua/cua";
      license = final.lib.licenses.mit;
      mainProgram = "cua-driver";
      platforms = [ "aarch64-darwin" ];
    };
  };
}
