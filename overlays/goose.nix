final: prev:
let
  inherit (prev) lib;
  sources = final.nvfetcherSources;
  platform = prev.stdenv.hostPlatform;
  cliSources = {
    aarch64-darwin = sources.goose-cli-bin;
    x86_64-darwin = sources.goose-cli-bin-x86_64-darwin;
  };
  desktopSources = {
    aarch64-darwin = sources.goose-desktop;
    x86_64-darwin = sources.goose-desktop-x86_64-darwin;
  };
in
lib.optionalAttrs platform.isDarwin {
  goose-cli = final.stdenvNoCC.mkDerivation {
    pname = "goose-cli";
    inherit (cliSources.${platform.system}) version src;
    sourceRoot = ".";
    dontStrip = true;
    nativeBuildInputs = [ final.makeWrapper ];
    installPhase = ''
      runHook preInstall
      install -Dm755 goose "$out/bin/goose"
      wrapProgram "$out/bin/goose" --prefix PATH : ${
        lib.makeBinPath [
          final.bash
          final.python3
        ]
      }
      runHook postInstall
    '';
    doInstallCheck = true;
    installCheckPhase = ''
      runHook preInstallCheck
      test "$("$out/bin/goose" --version | xargs)" = "${cliSources.${platform.system}.version}"
      "$out/bin/goose" run --help > /dev/null
      runHook postInstallCheck
    '';
    meta = prev.goose-cli.meta // {
      platforms = builtins.attrNames cliSources;
    };
  };

  goose-desktop = final.stdenvNoCC.mkDerivation {
    pname = "goose-desktop";
    inherit (desktopSources.${platform.system}) version src;
    sourceRoot = ".";
    nativeBuildInputs = [ final.unzip ];
    dontStrip = true;
    installPhase = ''
      runHook preInstall
      mkdir -p "$out/Applications"
      cp -R Goose.app "$out/Applications/"
      runHook postInstall
    '';
    doInstallCheck = true;
    installCheckPhase = ''
      runHook preInstallCheck
      test -x "$out/Applications/Goose.app/Contents/MacOS/Goose"
      test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$out/Applications/Goose.app/Contents/Info.plist")" = "${
        desktopSources.${platform.system}.version
      }"
      runHook postInstallCheck
    '';
    meta = {
      description = "Desktop client for Goose";
      homepage = "https://github.com/block/goose";
      license = lib.licenses.asl20;
      platforms = builtins.attrNames desktopSources;
    };
  };
}
