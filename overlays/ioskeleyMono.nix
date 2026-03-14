{ }:

final: _prev: {
  ioskeleyMono = final.stdenvNoCC.mkDerivation rec {
    pname = "ioskeleyMono";
    version = "2025.10.09-6";

    src = final.fetchurl {
      url = "https://github.com/ahatem/IoskeleyMono/releases/download/${version}/IoskeleyMono-TTF-Hinted.zip";
      sha256 = "sha256-yEZ29P2tJ4NaLbefu6yKGjPvp4HTnX4AXjMpd3idvpM=";
    };

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
