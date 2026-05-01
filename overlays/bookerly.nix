_:

final: _prev: {
  bookerly = final.stdenvNoCC.mkDerivation {
    pname = "bookerly";
    version = "0-unstable";

    src = final.fetchurl {
      url = "https://raw.githubusercontent.com/RadicalMilitantLibrary/www/master/fonts/Bookerly-Regular.ttf";
      hash = "sha256-tSFvJnxUCiMCW+yQV25yuQoM+oobFvLoVkf2oJzVP6k=";
      name = "Bookerly-Regular.ttf";
    };

    dontUnpack = true;

    installPhase = ''
      runHook preInstall
      install -Dm644 $src $out/share/fonts/truetype/Bookerly/Bookerly-Regular.ttf
      runHook postInstall
    '';
  };
}
