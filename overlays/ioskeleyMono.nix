{ }:

final: _prev:
let
  inherit (final.nvfetcherSources.ioskeleyMono) version src;
in
{
  ioskeleyMono = final.stdenvNoCC.mkDerivation {
    pname = "ioskeleyMono";
    inherit version src;

    nativeBuildInputs = [ final.unzip ];

    unpackPhase = ''
      unzip $src
    '';

    installPhase = ''
      runHook preInstall
      install -Dm644 TTF/*.ttf -t $out/share/fonts/truetype/IoskeleyMono
      runHook postInstall
    '';
  };
}
