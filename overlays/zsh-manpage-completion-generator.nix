{ lib, ... }:

final: _prev: {
  zsh-manpage-completion-generator = final.buildGoModule rec {
    pname = "zsh-manpage-completion-generator";
    version = "1.0.2";

    src = final.fetchFromGitHub {
      owner = "umlx5h";
      repo = "zsh-manpage-completion-generator";
      rev = "v${version}";
      hash = lib.fakeHash;
    };

    vendorHash = lib.fakeHash;

    meta = with final.lib; {
      description = "Generate zsh completions from man page";
      homepage = "https://github.com/umlx5h/zsh-manpage-completion-generator";
      license = licenses.mit;
      mainProgram = "zsh-manpage-completion-generator";
    };
  };
}
