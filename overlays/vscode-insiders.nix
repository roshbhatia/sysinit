_final: prev: {
  vscode-insiders = prev.stdenv.mkDerivation rec {
    pname = "vscode-insiders";
    version = "latest";

    src = prev.fetchurl {
      url = "https://code.visualstudio.com/sha/download?build=insider&os=darwin-universal";
      sha256 = "fb74f3c130b0f99570dc4172b6457423b70379635d7f4d5d75b55babd4c00df0";
    };

    dontUnpack = true;

    installPhase = ''
      mkdir -p $out/Applications
      cp $src $out/Applications/Visual\ Studio\ Code\ -\ Insiders.zip
      cd $out/Applications
      unzip "Visual Studio Code - Insiders.zip"
      rm "Visual Studio Code - Insiders.zip"
    '';

    meta = with prev.lib; {
      description = "Visual Studio Code Insiders - macOS Universal";
      platforms = platforms.darwin;
    };
  };
}
