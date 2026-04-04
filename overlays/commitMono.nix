{ }:

final: _prev:
let
  inherit (final.nvfetcherSources.commitMono) version src;
in
{
  commitMono = final.stdenvNoCC.mkDerivation {
    pname = "CommitMono";
    inherit version src;

    nativeBuildInputs = [ final.unzip ];

    unpackPhase = ''
      unzip $src
    '';

    installPhase = ''
      runHook preInstall
      install -Dm644 CommitMono-${version}/*.otf -t $out/share/fonts/opentype/CommitMono
      install -Dm644 CommitMono-${version}/ttfautohint/*.ttf -t $out/share/fonts/truetype/CommitMono
      runHook postInstall
    '';
  };
}
