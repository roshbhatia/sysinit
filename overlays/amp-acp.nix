final: _prev: {
  amp-acp = final.stdenvNoCC.mkDerivation {
    pname = "amp-acp";
    inherit (final.nvfetcherSources.amp-acp) version src;
    nativeBuildInputs = [ final.makeWrapper ];
    installPhase = ''
      runHook preInstall
      mkdir -p "$out/lib/amp-acp"
      cp -R dist package.json "$out/lib/amp-acp/"
      makeWrapper ${final.nodejs}/bin/node "$out/bin/amp-acp" \
        --add-flags "$out/lib/amp-acp/dist/index.js" \
        --prefix PATH : ${final.lib.makeBinPath [ final.amp-cli ]}
      runHook postInstall
    '';
    meta = {
      description = "Agent Client Protocol adapter for Amp";
      homepage = "https://github.com/tao12345666333/amp-acp";
      license = final.lib.licenses.mit;
      mainProgram = "amp-acp";
      platforms = final.amp-cli.meta.platforms;
    };
  };
}
