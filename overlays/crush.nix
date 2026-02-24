{ ... }:

final: _prev: {
  crush = final.buildGoModule rec {
    pname = "crush";
    version = "0.43.1";

    src = final.fetchFromGitHub {
      owner = "charmbracelet";
      repo = "crush";
      rev = "v${version}";
      hash = "sha256-WTu/OGxwAMk90i1tYTdznw9HYoW3pLdE88W8vEqqG4c=";
    };

    vendorHash = null;

    meta = with final.lib; {
      description = "A shared key-value store for the terminal";
      homepage = "https://github.com/charmbracelet/crush";
      license = licenses.mit;
      mainProgram = "crush";
    };
  };
}
