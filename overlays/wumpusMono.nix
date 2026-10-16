final: _prev: {
  wumpusMono = final.stdenvNoCC.mkDerivation {
    pname = "wumpusMono";
    version = "0-unstable-2026-04-22";

    src = final.fetchFromGitHub {
      owner = "vaughantype";
      repo = "wumpus-mono";
      rev = "7ff8e034ec253854b16bc3e65d9f47a687703cb5";
      hash = "sha256-eeYIKAuoRwgLm20v2PTr0DPGp8k5Co8+4/u+wklHlsc=";
    };

    installPhase = ''
      runHook preInstall
      install -Dm644 *.ttf -t $out/share/fonts/truetype/WumpusMono
      runHook postInstall
    '';
  };
}
