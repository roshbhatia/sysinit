final: _prev:
let
  sources = final.nvfetcherSources;
  platform = final.stdenv.hostPlatform;
  releases = {
    aarch64-darwin = sources.leaf;
    x86_64-darwin = sources.leaf-x86_64-darwin;
    aarch64-linux = sources.leaf-aarch64-linux;
    x86_64-linux = sources.leaf-x86_64-linux;
  };
in
{
  leaf-reader = final.stdenvNoCC.mkDerivation {
    pname = "leaf-reader";
    inherit (releases.${platform.system}) version src;
    sourceRoot = ".";
    dontConfigure = true;
    dontBuild = true;
    dontStrip = true;

    nativeBuildInputs = final.lib.optionals platform.isLinux [ final.autoPatchelfHook ];
    buildInputs = final.lib.optionals platform.isLinux [
      final.alsa-lib
      final.stdenv.cc.cc.lib
    ];

    installPhase = ''
      runHook preInstall
      install -Dm755 leaf "$out/bin/leaf"
      install -Dm644 LICENSE "$out/share/licenses/leaf-reader/LICENSE"
      install -Dm644 README.md "$out/share/doc/leaf-reader/README.md"
      runHook postInstall
    '';

    doInstallCheck = true;
    installCheckPhase = ''
      runHook preInstallCheck
      export HOME="$TMPDIR/home"
      mkdir -p "$HOME"
      test "$("$out/bin/leaf" version)" = "leaf $version"
      runHook postInstallCheck
    '';

    meta = with final.lib; {
      description = "Terminal reader for PDFs, Markdown, web articles, and diffs";
      homepage = "https://github.com/DeepanshuMishraa/leaf";
      license = licenses.mit;
      mainProgram = "leaf";
      platforms = builtins.attrNames releases;
      sourceProvenance = [ sourceTypes.binaryNativeCode ];
    };
  };
}
