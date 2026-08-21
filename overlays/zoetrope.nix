final: _prev: {
  # Pinned to a revision, not to `v0.1.0`: that tag has already been moved once
  # upstream, so a tag pin is not a pin. Bump the rev and both hashes together.
  zoetrope = final.rustPlatform.buildRustPackage {
    pname = "zoetrope";
    version = "0.1.0-unstable-2026-08-21";

    src = final.fetchFromGitHub {
      owner = "furkankly";
      repo = "zoetrope";
      rev = "562d48a3127c8e67e20e9be4a938b1c60622f025";
      hash = "sha256-9f6eoDT2J9uGNoh0r+VrxFrE7xwt7Ptl9Zk4JCDaLao=";
    };

    # Upstream builds one palette in src/state/graph.rs and every surface
    # resolves from it, so this reads the host base16 scheme into that palette.
    # The coral spawn glyph stays hardcoded on purpose: it is brand, not theme.
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
