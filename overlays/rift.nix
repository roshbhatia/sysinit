final: _prev: {
  rift = final.stdenvNoCC.mkDerivation {
    pname = "rift";
    version = "0.7.2";

    src = final.fetchurl {
      url = "https://github.com/acsandmann/rift/releases/download/v0.7.2/rift-universal-macos-0.7.2.tar.gz";
      hash = "sha256-fzZKWe6IkPgYLQyGMADpHlvZVrqI5Mrnd18IG0cH3UI=";
    };
    sourceRoot = ".";

    dontBuild = true;
    dontStrip = true;
    dontFixup = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 rift "$out/bin/rift"
      install -Dm755 rift-cli "$out/bin/rift-cli"
      install -Dm644 rift.default.toml "$out/share/rift/rift.default.toml"
      runHook postInstall
    '';

    meta = {
      description = "Fast, animated tiling window manager for macOS";
      homepage = "https://github.com/acsandmann/rift";
      license = final.lib.licenses.mit;
      platforms = final.lib.platforms.darwin;
      sourceProvenance = [ final.lib.sourceTypes.binaryNativeCode ];
    };
  };
}
