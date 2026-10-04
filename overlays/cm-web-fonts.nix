final: _prev: {
  cm-web-fonts = final.stdenvNoCC.mkDerivation {
    pname = "cm-web-fonts";
    version = "unstable-2024-07-21";
    src = final.fetchFromGitHub {
      owner = "bitmaks";
      repo = "cm-web-fonts";
      rev = "333f55ec19733c28cdc43567ecf72eafd6b0af61";
      hash = "sha256-RoxQwTRf79WHX0mUfzSfoOgv+BHmIt3EuGpkY+qsI9Y=";
    };
    installPhase = ''
      runHook preInstall
      mkdir -p "$out/share/fonts/truetype/computer-modern"
      find font -name '*.ttf' -exec install -m644 '{}' "$out/share/fonts/truetype/computer-modern/" \;
      install -Dm644 LICENSE.txt "$out/share/licenses/cm-web-fonts/LICENSE.txt"
      runHook postInstall
    '';
    meta = {
      description = "Computer Modern font family";
      homepage = "https://github.com/bitmaks/cm-web-fonts";
      license = final.lib.licenses.ofl;
      platforms = final.lib.platforms.all;
    };
  };
}
