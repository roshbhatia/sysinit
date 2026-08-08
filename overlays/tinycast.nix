final: _prev:
let
  inherit (final.nvfetcherSources.tinycast) version src;
in
{
  tinycast = final.stdenvNoCC.mkDerivation {
    pname = "tinycast";
    inherit version src;

    nativeBuildInputs = [ final._7zz ];

    unpackPhase = ''
      runHook preUnpack
      7zz x "$src" -o$PWD
      runHook postUnpack
    '';

    sourceRoot = ".";

    installPhase = ''
      runHook preInstall
      mkdir -p $out/Applications
      cp -R Tinycast.app $out/Applications/
      runHook postInstall
    '';

    dontFixup = true;

    meta = with final.lib; {
      description = "Native macOS launcher, hotkeys, clipboard history, and snippets";
      homepage = "https://github.com/abue-ammar/tinycast";
      license = licenses.agpl3Plus;
      platforms = platforms.darwin;
      sourceProvenance = [ sourceTypes.binaryNativeCode ];
    };
  };
}
