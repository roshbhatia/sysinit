final: _prev: {
  rex = final.stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "rex";
    version = "0.1.0-2061";

    src = final.fetchurl {
      url = "https://blob.superlogical.com/public/rex-app/preview/Rex-${finalAttrs.version}.dmg";
      hash = "sha256-deGRW0x+da5ez4TOJXqL/ImjR050ZQQm/sNhGCsP/7A=";
    };

    nativeBuildInputs = [ final.undmg ];
    sourceRoot = ".";
    dontFixup = true;

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/Applications" "$out/bin"
      mv Rex.app "$out/Applications/"
      ln -s '../Applications/Rex.app/Contents/Helpers/Rex Server.rex/Contents/MacOS/rex' "$out/bin/rex"
      runHook postInstall
    '';

    meta = with final.lib; {
      description = "Native terminal emulator and multiplexer";
      homepage = "https://www.superlogical.com/rex";
      license = licenses.unfree;
      mainProgram = "rex";
      platforms = platforms.darwin;
      sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    };
  });
}
