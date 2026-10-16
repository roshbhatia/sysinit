final: _prev: {

  zoetrope = final.rustPlatform.buildRustPackage {
    pname = "zoetrope";
    version = "0.2.0";

    src = final.fetchFromGitHub {
      owner = "furkankly";
      repo = "zoetrope";
      rev = "v0.2.0";
      hash = "sha256-jfzbgtZNIbDyHpXqP5QxF9o71zdYKEbY862NIaPHujo=";
    };

    patches = [ ./patches/zoetrope-base16.patch ];

    cargoHash = "sha256-6k+f07IusOyTudHsiOsBQGg00gd6NGP7nJU51inlfxU=";

    # Nix resets mtimes, but Codex fixture discovery bounds scans by the root's last write.
    preCheck = ''
      find assets/codex -type f -name '*.jsonl' -exec touch -t 202609080000.00 {} +
    '';

    meta = with final.lib; {
      description = "Watch a Claude Code session as a live flow graph in the terminal";
      homepage = "https://github.com/furkankly/zoetrope";
      license = licenses.mit;
      mainProgram = "zoe";
      platforms = platforms.unix;
    };
  };
}
