final: prev:
prev.lib.optionalAttrs (prev.stdenv.hostPlatform.system == "aarch64-darwin") {
  terminal-browser = final.stdenvNoCC.mkDerivation {
    pname = "terminal-browser";
    inherit (final.nvfetcherSources.terminal-browser) version src;
    sourceRoot = "terminal-browser";
    dontConfigure = true;
    dontBuild = true;
    dontStrip = true;

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/libexec/terminal-browser" "$out/bin"
      cp -R . "$out/libexec/terminal-browser/"
      ln -s "$out/libexec/terminal-browser/bin/terminal-browser" "$out/bin/terminal-browser"
      runHook postInstall
    '';

    doInstallCheck = true;
    installCheckPhase = ''
      runHook preInstallCheck
      /usr/bin/codesign --verify --deep --strict "$out/libexec/terminal-browser/electron/terminal-browser.app"
      mkdir -p "$TMPDIR/browser-home"
      env HOME="$TMPDIR/browser-home" "$out/bin/terminal-browser" --help > /dev/null
      env HOME="$TMPDIR/browser-home" "$out/bin/terminal-browser" config get window.transparent > /dev/null
      test ! -e "$TMPDIR/browser-home/.agents"
      test ! -e "$TMPDIR/browser-home/.claude"
      runHook postInstallCheck
    '';

    meta = with final.lib; {
      description = "Graphical browser embedded in a terminal";
      homepage = "https://github.com/roshbhatia/terminal-browser";
      license = licenses.mit;
      mainProgram = "terminal-browser";
      platforms = [ "aarch64-darwin" ];
      sourceProvenance = [ sourceTypes.binaryNativeCode ];
    };
  };
}
