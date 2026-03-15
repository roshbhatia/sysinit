{ }:

final: _prev: {
  commitMono = final.stdenvNoCC.mkDerivation rec {
    pname = "CommitMono";
    version = "1.143";

    src = final.fetchurl {
      url = "https://github.com/eigilnikolajsen/commit-mono/releases/download/v${version}/CommitMono-${version}.zip";
      sha256 = "sha256-99Hyanx1VIAKmW929dcGvwZIuTbKKma1vE1G46LEntA=";
    };

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
