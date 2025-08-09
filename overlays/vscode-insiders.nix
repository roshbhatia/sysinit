super: {
  vscode-insiders = super.stdenv.mkDerivation rec {
    pname = "vscode-insiders";
    version = "latest";

    src = super.fetchurl {
      url = "https://code.visualstudio.com/sha/download?build=insider&os=darwin-universal";
      sha256 = "0000000000000000000000000000000000000000000000000000";
    };

    dontUnpack = true;

    installPhase = ''
      mkdir -p $out/Applications
      cp $src $out/Applications/Visual\ Studio\ Code\ -\ Insiders.zip
      cd $out/Applications
      unzip "Visual Studio Code - Insiders.zip"
      rm "Visual Studio Code - Insiders.zip"
    '';

    meta = with super.lib; {
      description = "Visual Studio Code Insiders - macOS Universal";
      platforms = platforms.darwin;
    };
  };
}

