{ }:

final: _prev: {
  wumpusMono = final.stdenvNoCC.mkDerivation {
    pname = "wumpusMono";
    version = "0-unstable-2025-03-24";

    src = final.fetchFromGitHub {
      owner = "vaughantype";
      repo = "wumpus-mono";
      rev = "aaf431bbcf0221792cfa17742bc1d2e81412f5df";
      hash = "sha256-udUrOherol4aXYozkcRcMarNuPbJMHgO/b18MbVN45M=";
    };

    installPhase = ''
      runHook preInstall
      install -Dm644 *.ttf -t $out/share/fonts/truetype/WumpusMono
      runHook postInstall
    '';
  };
}
