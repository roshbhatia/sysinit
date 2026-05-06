_:

final: _prev: {
  anomalyMono = final.stdenvNoCC.mkDerivation {
    pname = "anomalyMono";
    version = "0-unstable-2021-10-24";

    src = final.fetchFromGitHub {
      owner = "benbusby";
      repo = "anomaly-mono";
      rev = "3f1d10fe8ee2c4da32c65a784164c494102c3f83";
      hash = "sha256-XRQKCXz+Vd5OeGbL8ZGvT8LfbvxAi1LD8hTZoLEUCIE=";
    };

    installPhase = ''
      runHook preInstall
      install -Dm644 AnomalyMono-Powerline.otf -t $out/share/fonts/opentype/AnomalyMono
      runHook postInstall
    '';
  };
}
