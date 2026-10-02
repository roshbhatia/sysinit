final: _prev: {

  zoetrope = final.rustPlatform.buildRustPackage {
    pname = "zoetrope";
    version = "0.1.0-unstable-2026-08-21";

    src = final.fetchFromGitHub {
      owner = "furkankly";
      repo = "zoetrope";
      rev = "562d48a3127c8e67e20e9be4a938b1c60622f025";
      hash = "sha256-9f6eoDT2J9uGNoh0r+VrxFrE7xwt7Ptl9Zk4JCDaLao=";
    };

    patches = [ ./patches/zoetrope-base16.patch ];

    cargoHash = "sha256-QD2LarTvt9tovkA98b0jw5t0LX5+Bxp7Om0yiKcWU30=";

    meta = with final.lib; {
      description = "Watch a Claude Code session as a live flow graph in the terminal";
      homepage = "https://github.com/furkankly/zoetrope";
      license = licenses.mit;
      mainProgram = "zoe";
      platforms = platforms.unix;
    };
  };
}
