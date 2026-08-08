final: _prev: {
  alerter = final.stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "alerter";
    version = "26.5";

    src = final.fetchurl {
      url = "https://github.com/vjeantet/alerter/releases/download/v${finalAttrs.version}/alerter-${finalAttrs.version}.zip";
      hash = "sha256-EfY83cm7P4VU7Zt2JjKhIM+nvuBePAnWVzSCPgnSTxA=";
    };

    nativeBuildInputs = [ final.unzip ];

    unpackPhase = ''
      runHook preUnpack
      mkdir -p source
      unzip -q "$src" -d source
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall
      install -Dm755 source/alerter "$out/bin/alerter"
      runHook postInstall
    '';

    meta = with final.lib; {
      description = "terminal-notifier fork that returns the user's action choice";
      homepage = "https://github.com/vjeantet/alerter";
      license = licenses.mit;
      mainProgram = "alerter";
      platforms = platforms.darwin;
      sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    };
  });
}
